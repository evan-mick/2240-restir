
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


Looking at numbers for pdf doesn't do much. 

Area restir.


Scene with many many lights, some of them rotated away. 
Scene like that will work the best. Bias random triangles to the side. 

Third scene with restir improvements, and see if improvements with spatial reuse. 

Look at reference for temporal reuse. 
- standard, using ris paper's "domain" changes. 
- jacobian tacked on to W


Some numerical quantification, write a script that can do MSE vs a quantitative render. See quantitatively compared to noise. 


Extensions
- try different methods for calculating weights
- try different sampling methods
    - index
    - direction
    - index and position
- tiling system?
- accumulation stuff
    - set frames for accumulation



Arin -> Lights
Evan -> Extensions start, getting stuff on better computer
Trey -> Intel scenes

Will meet saturday at 12, work for a while. Move on to temporal start. 


Try different PDFs for extension?


Need list of stuff we need for spatial and temporal

Randomize spatial sampling

Storing distance and normal for spatial
discard if too far


Temporal
previous inverse rotation
previous position
previous view/forward


camera should be updated to have previous stuff
put uniforms for previous stuff in
calculate inverse rotation 
pass in inverse rotation

copy over code for temporal


For our sample
- emission
- direction (full)
- no more pdf (?)
