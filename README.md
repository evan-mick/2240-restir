
# An OpenGL ReSTIR implementation

This uses a premade pathtracer with modifications on top for direct light sample reuse

Seems like we're doing stuff for "Analytic lights" in "DirectLight" in pathtrace.glsl, around line 216


TODO:

- Get a large scene file
- re-examine sampling strategy
    - \omega_o or add a position to the light
- W werid values



- Per pixel jitter
    - have randomization from pixel level, or same ray shot, but bounce different for different samples

Ran into a bug where the reservoirs weren't working creating weird offsets, after much search and logical lookups, it was that we hadn't passed in the uniforms for the camera leading to weird intersections and thus weird samples. 



