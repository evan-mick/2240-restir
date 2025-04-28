
void SaveReservoir(Reservoir res) {
    reservoirOut0 = vec4(float(res.sam.index), res.sam.weight, 0, 0); //vec4(res.sam.radiance, res.sam.direction.x);
    reservoirOut1 = vec4(0, 0, res.sumWeights, res.sam.pdf); // res.sam.direction.yz,
    reservoirOut2 = vec4(float(res.numberOfWeights), res.W, 0.0, 0.0);
}

Reservoir GetReservoirFromPosition(ivec2 pos) {
    Reservoir res;

    vec4 first = texelFetch(reservoirs0, pos, 0);
    vec4 second = texelFetch(reservoirs1, pos, 0);
    vec4 third = texelFetch(reservoirs2, pos, 0);

    //res.sam.radiance = first.xyz;
    //res.sam.direction = vec3(first.a, second.xy);

    res.sam.index = int(first.x);
    res.sam.pdf = second.a;
    res.sam.weight = first.y;

    res.sumWeights = second.z;
    res.numberOfWeights = int(third.x);
    res.W = third.y;

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
    r.sumWeights += weight;
    r.numberOfWeights += 1;
    if (rand() < (weight / r.sumWeights)) {
        r.sam = sam;
    }
    return r;
}
//
float CalculateW(Reservoir res) {
    //return (1.0 / (res.sam.radiance)) * (res.sumWeights / float(res.numberOfWeights));
    return (1.0 / float(res.sam.weight)) * (float(res.sumWeights) / float(res.numberOfWeights));
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

Reservoir CombineReservoirs(Reservoir main, Reservoir new)
{
    return main;
}
