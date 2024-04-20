#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Input texture
layout(r32ui, set = 0, binding = 2) restrict readonly uniform uimage2D in_tex;

// Output texture
layout(rgba32f, set = 0, binding = 1) restrict writeonly uniform image2D out_tex;

void main() {
  float r = float(imageLoad(in_tex, ivec2(gl_GlobalInvocationID.xy))) / 255.0;
  imageStore(out_tex, ivec2(gl_GlobalInvocationID.xy), vec4(r, 0., 0., 1.0));
  // imageStore(out_tex, ivec2(gl_GlobalInvocationID.xy), vec4(1.0, 0., 0., 1.0));
}