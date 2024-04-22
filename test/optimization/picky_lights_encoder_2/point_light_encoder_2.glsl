#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Light textures for each point light being processed.
layout(rgba32f, set = 0, binding = 0) restrict readonly uniform image2DArray light_textures;

struct Light {
  ivec2 pos;
};

// Other input data
layout(set = 0, binding = 1, std430) restrict readonly buffer Data {
  ivec2 main_pos;
  int num_lights;
  Light[] light_data;
}
data;

// Output image that is the encoded light texture.
layout(r32f, set = 0, binding = 2) restrict writeonly uniform image2D encoded_lights;

void main() {
  ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);

  // Iterate over every light and find the brightest color
  // at that pixel. Light val is in range [0-255].
  float light = 0.0;
  // for (int i = 0; i < data.num_lights; i++) {
  //   vec4 color = imageLoad(
  //     light_textures,
  //     ivec3(pixel - data.main_pos - data.light_data[i].pos, i)
  //   );
  //   // Find the average of the color channels,
  //   // then convert it to a uint ranging 0-255.
  //   light = max(light, (color.r + color.g + color.b) / 3.0);
  // }

  if (pixel.x == data.light_data[0].pos.x || pixel.y == data.light_data[0].pos.y) {
    light = 1.0;
  }

  imageStore(encoded_lights, pixel, vec4(light, 0, 0, 1.0));
}