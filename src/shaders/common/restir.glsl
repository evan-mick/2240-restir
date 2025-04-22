
//struct Sample {
//    vec3 color;
//    float weight;
//};

//struct LightSampleRec
//{
//    vec3 normal;
//    vec3 emission;
//    vec3 direction;
//    float dist;
//    float pdf;
//};

void SaveReservoir(Reservoir res) {
    reservoirOut0 = vec4(res.picked.normal.x, res.picked.normal.y, res.picked.normal.z, res.picked.emission.x);
    reservoirOut1 = vec4(res.picked.emission.y, res.picked.emission.z, res.picked.direction.x, res.picked.direction.y);
    reservoirOut2 = vec4(res.picked.direction.z, res.picked.dist, res.picked.pdf, res.sumWeights);
}

Reservoir GetReservoirFromPosition(ivec2 pos) {
    //    Reservoir res;
    //    res.picked.normal = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 0, pos.y), 0);
    //    res.picked.emission = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 1, pos.y), 0);
    //    res.picked.direction = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 2, pos.y), 0);
    //
    //    vec3 finalThree = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 3, pos.y), 0);
    //
    //    res.picked.dist = finalThree.x;
    //    res.picked.pdf = finalThree.y;
    //    res.sumWeights = finalThree.z;

    Reservoir res;
    vec4 first = texelFetch(reservoirs0, pos, 0);
    vec4 second = texelFetch(reservoirs1, pos, 0);
    vec4 third = texelFetch(reservoirs2, pos, 0);

    res.picked.normal = first.xyz;
    res.picked.emission = vec3(first.a, second.x, second.y);
    res.picked.direction = vec3(second.z, second.a, third.x);
    res.picked.dist = third.y;
    res.picked.pdf = third.z;
    res.sumWeights = third.a;

    return res;
}

Reservoir UpdateReservoir(Reservoir r, LightSampleRec s)
{
    float weight = s.pdf; // NEED TO LOOK INTO THIS
    r.sumWeights += weight;
    if (rand() < weight / r.sumWeights) {
        r.picked = s;
    }
    return r;
}

Reservoir CombineReservoirs(Reservoir main, Reservoir new)
{
    return main;
}
