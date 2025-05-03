
void SaveReservoir(Reservoir res) {
    reservoirOut0 = vec4(float(res.numberOfWeights), res.W, res.sumWeights, res.sam.pdf); // res.sam.direction.yz,
    reservoirOut1.x = res.sam.weight;
    #ifdef RESTIR_SAMPLE_INDEX_POSITION
    reservoirOut1.y = float(res.sam.index); //vec4(res.sam.radiance, res.sam.direction.x);
    reservoirOut2 = vec4(res.sam.position, 0); // Position here
    #elif RESTIR_SAMPLE_DIRECTION
    reservoirOut1 = vec4(res.sam.weight, res.sam.direction); //vec4(res.sam.radiance, res.sam.direction.x);
    reservoirOut2 = vec4(0, 0, 0, 0); // Position here
    #else // By default, use index based sampling
    reservoirOut1.y = float(res.sam.index); //vec4(float(res.sam.index), res.sam.weight, 0, 0); //vec4(res.sam.radiance, res.sam.direction.x);
    reservoirOut2 = vec4(0, 0, 0, 0);
    #endif
}

Reservoir GetReservoirFromPosition(ivec2 pos) {
    Reservoir res;

    vec4 first = texelFetch(reservoirs0, pos, 0);
    vec4 second = texelFetch(reservoirs1, pos, 0);
    vec4 third = texelFetch(reservoirs2, pos, 0);

    //res.sam.radiance = first.xyz;
    //res.sam.direction = vec3(first.a, second.xy);

    res.numberOfWeights = int(first.x);
    res.W = first.y;
    res.sumWeights = first.z;
    res.sam.pdf = first.a;
    res.sam.weight = second.x;

    /*


                                                                                        struct LightSampleRec
                                                                                        {
                                                                                            vec3 normal;
                                                                                            vec3 emission;
                                                                                            vec3 direction;
                                                                                            float dist;
                                                                                            float pdf;
                                                                                        };
                                                                                            */

    #ifdef RESTIR_SAMPLE_INDEX_POSITION
    res.sam.index = int(second.y);
    res.sam.position = third.xyz;
    #elif RESTIR_SAMPLE_DIRECTION
    res.sam.direction = second.yza;
    #else
    res.sam.index = int(second.y);
    #endif

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
    float weightDiv = weight / r.sumWeights;
    if (rand() < (weightDiv)) {
        r.sam = sam;
    }
    return r;
}
//
float CalculateW(Reservoir res) {
    //return (1.0 / (res.sam.radiance)) * (res.sumWeights / float(res.numberOfWeights));
    return (float(res.sumWeights) / float(res.numberOfWeights)) / (res.sam.weight * float(res.sam.pdf));
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
    return (radiance.x + radiance.y + radiance.z) / 3;
    #endif
}

Reservoir CombineReservoirs(Reservoir main, Reservoir new)
{
    UpdateReservoir(main, new.sam, float(new.W) * float(new.numberOfWeights) * float(new.sam.weight));
    main.numberOfWeights += new.numberOfWeights;
    main.sumWeights += new.sumWeights;
    main.W = CalculateW(main);
    return main;
}
