import random

def parse_scene(scene_path):
    with open(scene_path, 'r') as f:
        lines = f.readlines()
    return lines

def generate_lights(count, pattern="uniform", bbox=None, emission=(5, 5, 5)):
    lights = []
    for i in range(count):
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

        dx, dz = 0.5, 0.5
        v1 = f"{x + dx} {y} {z - dz}"
        v2 = f"{x - dx} {y} {z + dz}"
        emission_str = f"{emission[0]} {emission[1]} {emission[2]}"

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
    scene = "cornell_box_orig"
    input_scene_path = f"assets/{scene}.scene"
   

    # Light generation parameters
    num_lights = 100
    pattern = "uniform"  # or "uniform"
    bbox = (-10, 5, -10, 10, 10, 10)  # Only used for random
    emission_color = (10, 0, 2)

    base_output_name = f"assets/p_{scene}"
    output_scene_path = f"{base_output_name}_{num_lights}.scene"

    # Execution
    base_scene = parse_scene(input_scene_path)
    lights = generate_lights(num_lights, pattern=pattern, bbox=bbox, emission=emission_color)
    write_scene_with_lights(base_scene, lights, output_scene_path)

    print(f"✅ Generated {num_lights} lights with '{pattern}' pattern and saved to '{output_scene_path}'")
