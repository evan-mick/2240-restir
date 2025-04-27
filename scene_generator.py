import random

def parse_scene(scene_path):
    with open(scene_path, 'r') as f:
        lines = f.readlines()
    return lines

def generate_lights(count, pattern="uniform", bbox=None, emission=(5, 5, 5), xz_offset = 0.1):
    lights = []
    
    for i in range(count):
        light_emission = (0, 0, 0)
        if pattern == "uniform":
            side = int(count ** (1 / 3)) + 1
            x = (i % side) * 1.0
            y = ((i // side) % side) * 1.0 + 5.0
            z = (i // (side * side)) * 1.0
        elif pattern == "random":
            if bbox is None:
                raise ValueError("Random pattern requires bbox.")
            minx, miny, minz, maxx, maxy, maxz = bbox
            x = random.uniform(minx, maxx)
            y = random.uniform(miny, maxy)
            z = random.uniform(minz, maxz)
        else:
            raise ValueError("Unsupported pattern: use 'uniform' or 'random'")

        if i % 17 == 0:
            light_emission = emission
            


        dx, dz = -xz_offset, xz_offset
        v1 = f"{x} {y} {z + dz}"
        v2 = f"{x + dx} {y} {z}"
        emission_str = f"{light_emission[0]} {light_emission[1]} {light_emission[2]}"

        light_block = f"""light
{{
\ttype quad
\tposition {x} {y} {z}
\tv1 {v1}
\tv2 {v2}
\temission {emission_str}
}}\n"""
        lights.append(light_block)
    return lights

def write_scene_with_lights(original_lines, lights, out_path):
    with open(out_path, 'w') as f:
        for line in original_lines:
            f.write(line)
        f.write("\n# Generated Lights\n")
        for light in lights:
            f.write(light)

# ----------------------
# Configuration
# ----------------------

if __name__ == "__main__":
    # Scene files
    scene = "cornell_box_test_emissives"
    input_scene_path = f"assets/{scene}.scene"
   

    # Light generation parameters
    num_lights = 100
    pattern = "random"  # or "uniform"
    #xyz min, xyz max
    bbox = (
        0.213, 0.4378, 0.227,   # min x, min y, min z
        0.343, 0.5478, 0.332    # max x, max y, max z
    )
    x_z_offset = 0.05
    emission_color = (17, 12, 5)

    base_output_name = f"assets/p_{scene}"
    output_scene_path = f"{base_output_name}_{num_lights}.scene"

    # Execution
    base_scene = parse_scene(input_scene_path)
    lights = generate_lights(num_lights, pattern=pattern, bbox=bbox, emission=emission_color, xz_offset=x_z_offset)
    write_scene_with_lights(base_scene, lights, output_scene_path)

    print("Testsiygssg")
    print(f"✅ Generated {num_lights} lights with '{pattern}' pattern and saved to '{output_scene_path}'")
