

/*struct ReservoirSample {
    int index;
    vec3 fullDirection;
    vec3 normal;
    vec3 radiance;
    float camDist;

    // Could storing just the index mess up big W? won't the new radiance be off?
    //I think we deffinitely need radiance?
    float pdf;
    float weight;
};

struct Reservoir {
    ReservoirSample sam;
    //float pdf;
    float sumWeights;
    int numberOfWeights;
    float W;

    // big W (weight offset) = 1/radiance * (sumWeights / numberOfWeights)
};*/

Reservoir ResetReservoirCounters(Reservoir res) {
    res.sumWeights = res.sam.weight > 0.0 ? res.sam.weight : 0.0;
    res.numberOfWeights = res.sam.weight > 0.0 ? 1 : 0;
    res.W = res.sam.weight > 0.0 ? 1.0 : 0.0;
    return res;
}

void SaveReservoir(Reservoir res) {
    reservoirOut0 = vec4(float(res.numberOfWeights), res.W, res.sumWeights, res.sam.pdf); // res.sam.direction.yz,
    reservoirOut1 = vec4(res.sam.weight, res.sam.hitPosition);
    reservoirOut2 = vec4(res.sam.camDist, res.sam.fullDirection);
    reservoirOut3 = vec4(float(res.sam.index), res.sam.radiance);
}

Reservoir GetReservoirFromPosition(ivec2 pos) {
    Reservoir res;

    vec4 first = texelFetch(reservoirs0, pos, 0);
    vec4 second = texelFetch(reservoirs1, pos, 0);
    vec4 third = texelFetch(reservoirs2, pos, 0);
    vec4 fourth = texelFetch(reservoirs3, pos, 0);

    //res.sam.radiance = first.xyz;
    //res.sam.direction = vec3(first.a, second.xy);

    res.numberOfWeights = int(first.x);
    res.W = first.y;
    res.sumWeights = first.z;
    res.sam.pdf = first.w;

    res.sam.weight = second.x;
    res.sam.hitPosition = second.yzw;

    res.sam.camDist = (third.x);
    res.sam.fullDirection = third.yzw;

    res.sam.index = int(fourth.x);
    res.sam.radiance = fourth.yzw;
    // Old
    //res.picked.normal = first.xyz;
    //res.picked.emission = vec3(first.a, second.x, second.y);
    //res.picked.direction = vec3(second.z, second.a, third.x);
    //res.picked.dist = third.y;
    //res.picked.pdf = third.z;
    //res.sumWeights = third.a;

    return res;
}

Reservoir UpdateReservoir(Reservoir r, ReservoirSample sam, float weight) {
    if (weight <= 0.000001) {
        return r;
    }

    r.sumWeights += weight;
    r.numberOfWeights += 1;
    float weightDiv = weight / r.sumWeights;
    if (rand() < (weightDiv)) {
        r.sam = sam;
    }
    return r;
}

mat3 GetCameraInverseRotation() {
    return transpose(mat3(prevCamera.right, prevCamera.up, prevCamera.forward)); // orthonormal matrix inverse is transpose, thx gpt
}

//
float CalculateW(Reservoir res) {
    //return (1.0 / (res.sam.radiance)) * (res.sumWeights / float(res.numberOfWeights));

    float denom = res.sam.weight * float(res.sam.pdf);

    if (denom > 0)
        denom = float(res.numberOfWeights) / denom;
    else
        return 0.0;

    if (denom > 0)
        return (res.sumWeights) / denom;

    return 0.0;
}
//Reservoir UpdateReservoir(Reservoir r, LightSampleRec s)
//{
//    float weight = s.pdf; // NEED TO LOOK INTO THIS
//    r.sumWeights += weight;
//    //if (rand() < weight / r.sumWeights) {
//    //r.picked = s;
//    //}
//    return r;
//}

float CalculatePHat(vec3 radiance) {
    #if defined(PHAT_LUMINANCE)
    return Luminance(radiance);
    #elif defined(PHAT_MAX)
    return max(radiance.z, max(radiance.x, radiance.y));
    #elif defined(PHAT_CONST)
    return 0.01;
    #else
    return length(radiance);
    #endif
}

Reservoir CombineReservoirs(Reservoir main, Reservoir new)
{
    float safeNumberOfWeights = min(20.0 * float(main.numberOfWeights), float(new.numberOfWeights));
    main = UpdateReservoir(main, new.sam, float(new.W) * safeNumberOfWeights * (float(new.sam.weight) * new.sam.pdf));
    //main.numberOfWeights += int(safeNumberOfWeights);
    //main.sumWeights += new.sumWeights;
    main.W = CalculateW(main);
    return main;
}
