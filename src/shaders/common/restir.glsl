
struct Sample {
    vec3 color;
    float weight;
};

struct Reservoir {
    Sample picked;
    float sumWeights;
};

Reservoir updateReservoir(Reservoir r, Sample s)
{
    r.sumWeights += s.weight;
    if (rand() < s.weight / r.sum_weights) {
        r.picked = s;
    }
    return r;
}
