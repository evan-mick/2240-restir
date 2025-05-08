import random
import numpy as np
import math



def parse_scene(scene_path):
    with open(scene_path, 'r') as f:
        lines = f.readlines()
    return lines

def offset_normal(normal, jitter_degrees=10):
    """
    Offsets a unit normal vector by a random direction within a cone of 'jitter_degrees'.

    Args:
        normal (array-like): Original unit normal vector (3D).
        jitter_degrees (float): Maximum angular deviation from the normal in degrees.

    Returns:
        np.ndarray: Jittered normal, still normalized.
    """
    normal = np.array(normal)
    jitter_radians = np.radians(jitter_degrees)

    # Generate a random direction within a cone of angle 'jitter_radians' around the normal
    # Step 1: Create a random vector in a local coordinate system where the Z-axis is the original normal
    theta = np.random.uniform(0, 2 * np.pi)
    phi = np.random.uniform(0, jitter_radians)

    # Local spherical to Cartesian
    x = np.sin(phi) * np.cos(theta)
    y = np.sin(phi) * np.sin(theta)
    z = np.cos(phi)

    # Step 2: Construct orthonormal basis around the normal
    def orthonormal_basis(n):
        n = n / np.linalg.norm(n)
        if abs(n[0]) < abs(n[1]):
            tangent = np.cross(n, [1,0,0])
        else:
            tangent = np.cross(n, [0,1,0])
        tangent = tangent / np.linalg.norm(tangent)
        bitangent = np.cross(n, tangent)
        return tangent, bitangent, n

    tangent, bitangent, normal_z = orthonormal_basis(normal)

    # Transform local offset to world space
    offset = x * tangent + y * bitangent + z * normal_z
    return offset / np.linalg.norm(offset)

def sample_hemis(world_pos, num_lights, radius=0.3, up=True):
    points = []
    norms = []

    world_pos = np.array(world_pos)

    # Decide number of rings
    rings = int(math.sqrt(num_lights))
    if rings < 1:
        rings = 1

    # Sample theta from 0 to π/2 (upper hemisphere)
    theta_vals = [(math.pi / 2) * (i / rings) for i in range(1, rings + 1)]
    weights = [math.sin(t) for t in theta_vals]
    total_weight = sum(weights)

    # Compute how many points go into each ring
    per_ring_counts = [max(1, int(num_lights * (w / total_weight))) for w in weights]

    for theta, count in zip(theta_vals, per_ring_counts):
        for j in range(count):
            phi = (2 * math.pi * j) / count  # full circle

            # Spherical to Cartesian
            x = math.sin(theta) * math.cos(phi)
            y = math.cos(theta)
            z = math.sin(theta) * math.sin(phi)

            a = -1.0
            if not up:
                y = -y  # Flip the hemisphere downward
                a = 1.0


            normal = np.array([x, y, z])
            point = world_pos + radius * normal
            normal *= a

            points.append(point.tolist())
            norms.append(normal.tolist())

    return points, norms

def sample_plane(world_pos, num_lights, width=4.0, height=4.0):
    points = []
    norms = []

    world_pos = np.array(world_pos)

    # Determine grid dimensions (rows x cols)
    cols = int(math.sqrt(num_lights))
    rows = max(1, num_lights // cols)

    # Generate grid in local space centered at origin
    for i in range(rows):
        for j in range(cols):
            if len(points) >= num_lights:
                break

            u = (j + 0.5) / cols - 0.5  # from -0.5 to 0.5
            v = (i + 0.5) / rows - 0.5  # from -0.5 to 0.5

            local_pos = np.array([u * width, 0, v * height])
            point = world_pos + local_pos
            normal = [0, -1, 0]  # Upward-facing normal

            points.append(point.tolist())
            norms.append(normal)

    return points, norms

def generate_light(point, normal, size=0.1, emission=(5, 5, 5)):
    # Ensure inputs are numpy arrays
    center = np.array(point)
    normal = np.array(normal)
    normal = normal / np.linalg.norm(normal)

    # Generate a basis in the tangent plane
    if np.allclose(normal, [0, 1, 0]) or np.allclose(normal, [0, -1, 0]):
        tangent = np.array([1, 0, 0])
    else:
        tangent = np.cross(normal, [0, 1, 0])
    tangent = tangent / np.linalg.norm(tangent)
    bitangent = np.cross(normal, tangent)

    # Half extents of the quad
    u = tangent * (size / 2)
    v = bitangent * (size / 2)

    # Calculate two vertices in the quad (note: these are not the only corners, just defining orientation)
    v1 = center + u
    v2 = center + v

    # Format the output
    v1_str = f"{v1[0]:.8f} {v1[1]:.8f} {v1[2]:.8f}"
    v2_str = f"{v2[0]:.8f} {v2[1]:.8f} {v2[2]:.8f}"
    pos_str = f"{center[0]:.8f} {center[1]:.8f} {center[2]:.8f}"
    emission = [random.uniform(0, 30) for _ in range(3)]
    emission_str = f"{emission[0]} {emission[1]} {emission[2]}"

    light_block = f"""light
{{
\ttype quad
\tposition {pos_str}
\tv1 {v1_str}git ch
\tv2 {v2_str}
\temission {emission_str}
}}\n"""

    return light_block


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
    dome_pos = (0, -6, 0)
    num_lights = 1000
    scene = "a__geom"
    input_scene_path = f"assets/{scene}.scene"
    base_output_name = f"assets/a__aaa_aupteststarry_night{scene}"
    output_scene_path = f"{base_output_name}_{num_lights}.scene"
   
    
    base_scene = parse_scene(input_scene_path)

    points, normals = sample_hemis(dome_pos, num_lights=num_lights, radius=9, up=True)
    normals = [offset_normal(n, jitter_degrees=90) for n in normals]

    lights = []
    for p, n in zip(points, normals):
        light = generate_light(p,n)
        lights.append(light)

    write_scene_with_lights(base_scene, lights, output_scene_path)

    print(f"Generated {num_lights} lights with pattern and saved to '{output_scene_path}'")
