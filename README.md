
# An OpenGL ReSTIR implementation

This uses a premade pathtracer with modifications on top for direct light sample reuse

Seems like we're doing stuff for "Analytic lights" in "DirectLight" in pathtrace.glsl, around line 216


TODO:

the texture needs to be of arbitrary sizing to store the reservoirs across textures
We need to figure out what needs to be stored in the reservoirs (light samples) and then edit how much the texture and how its accessed in GLSL
