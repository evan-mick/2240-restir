
//struct Sample {
//    vec3 color;
//    float weight;
//};

struct Reservoir {
    LightSampleRec picked;
    float sumWeights;
};

//struct LightSampleRec
//{
//    vec3 normal;
//    vec3 emission;
//    vec3 direction;
//    float dist;
//    float pdf;
//};

Reservoir getReservoirFromPosition(sampler2D sampleFrom, ivec2 pos) {
    Reservoir res;
    res.picked.normal = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 0, pos.y), 0);
    res.picked.emission = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 1, pos.y), 0);
    res.picked.direction = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 2, pos.y), 0);

    vec3 finalThree = texelFetch(sampleFrom, (pos.x * sizeof(Reservoir) + 3, pos.y), 0);

    res.picked.dist = finalThree.x;
    res.picked.pdf = finalThree.y;
    res.sumWeights = finalThree.z;

    return res;
}

Reservoir updateReservoir(Reservoir r, Sample s)
{
    r.sumWeights += s.weight;
    if (rand() < s.weight / r.sum_weights) {
        r.picked = s;
    }
    return r;
}
