
void SaveReservoir(Reservoir res) {
    reservoirOut0 = vec4(res.sam.radiance, res.sam.direction.x);
    reservoirOut1 = vec4(res.sam.direction.yz, res.sumWeights, res.pdf);
    reservoirOut2 = vec4(res.numberOfWeights, 0.0, 0.0, 0.0);
}

Reservoir GetReservoirFromPosition(ivec2 pos) {
    Reservoir res;

    vec4 first = texelFetch(reservoirs0, pos, 0);
    vec4 second = texelFetch(reservoirs1, pos, 0);
    vec4 third = texelFetch(reservoirs2, pos, 0);

    res.sam.radiance = first.xyz;
    res.sam.direction = vec3(first.a, second.xy);
    res.sumWeights = second.z;
    res.pdf = second.a;
    res.numberOfWeights = third.x;

    // Old
    //res.picked.normal = first.xyz;
    //res.picked.emission = vec3(first.a, second.x, second.y);
    //res.picked.direction = vec3(second.z, second.a, third.x);
    //res.picked.dist = third.y;
    //res.picked.pdf = third.z;
    //res.sumWeights = third.a;

    return res;
}

Reservoir UpdateReservoir(Reservoir r, float weight, vec3 radiance, vec3 direction) {}
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
