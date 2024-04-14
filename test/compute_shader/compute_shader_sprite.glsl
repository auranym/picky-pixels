#[compute]
#version 450
 
// Color palette
// const int PALETTE_SIZE = 4;
// const vec3[4] PALETTE = vec3[4](
//   vec3(225.0 / 255.0, 247.0 / 255.0, 249.0 / 255.0),
//   vec3(140.0 / 255.0, 189.0 / 255.0, 197.0 / 255.0),
//   vec3(31.0 / 255.0, 119.0 / 255.0, 137.0 / 255.0),
//   vec3(0.0 / 255.0, 73.0 / 255.0, 91.0 / 255.0)
// );

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
 
// Input and output textures
layout(set = 0, binding = 0, rgba32f) restrict readonly uniform image2D img_in;
layout(set = 0, binding = 1, rgba32f) restrict writeonly uniform image2D img_out;

// layout(set = 0, binding = 2) restrict buffer Params {
//   float time;
// }
// params;

void main() {
  // vec4 pixel = imageLoad(img_in, ivec2(gl_GlobalInvocationID.xy));
  // int palette_index = int(min(
  //   PALETTE_SIZE-1, floor(
  //     float(PALETTE_SIZE) * (sin(3.14159 * (params.time + params.pos_x + params.pos_y)) + 1.0) / 2.0
  //   )
  // ));
  // imageStore(img_out, ivec2(gl_GlobalInvocationID.xy), vec4(PALETTE[palette_index], pixel.a));

  vec4 pixel = imageLoad(img_in, ivec2(gl_GlobalInvocationID.xy));
  imageStore(img_out, ivec2(gl_GlobalInvocationID.xy), vec4(0.0, 1.0 - pixel.g, 0.0, pixel.a));
}