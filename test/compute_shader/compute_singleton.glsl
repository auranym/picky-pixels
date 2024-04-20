#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Light texture
layout(r32f, set = 0, binding = 0) restrict readonly uniform image2D in_tex;

// Other data
// layout(set = 0, binding = 1, std430) restrict readonly buffer Data {
//   vec2 main_size;
// }
// in_data;

layout(r32ui, set = 0, binding = 2) uniform uimage2D out_tex;

void main() {
  imageAtomicMax(
    out_tex,
    ivec2(gl_GlobalInvocationID.xy),
    uint(255.0 * imageLoad(in_tex, ivec2(gl_GlobalInvocationID.xy)).r)
  );
}