#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Array of sprites for each light level:
// sprites[0] => sprite at light level 0, etc.
// Length is defined in "data"
layout(rgba32f, set = 0, binding = 0) restrict readonly uniform image2DArray sprites;

layout(rgba32f, set = 0, binding = 1) restrict readonly uniform image2DArray light_textures;

// struct Light {
//   ivec2 texture_size;
// };

layout(set = 0, binding = 2, std430) restrict readonly buffer Data {
  int sprites_length;
  int lights_data_length;
  ivec2 sprite_size;
  // Light[] lights_data;
}
data;

layout(rgba32f, set = 0, binding = 3) restrict writeonly uniform image2D out_sprite;

void main() {
  ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
  // Find the highest average color for every light texture
  float max_light_val = 0.0;
  for (int i = 0; i < data.lights_data_length; i++) {
    vec4 light_color = imageLoad(light_textures, ivec3(pixel.xy, i));
    max_light_val = max(max_light_val, (light_color.r + light_color.g + light_color.b) / 3.0);
  }
  // Convert max_light_val to an int within range [0, data.sprites_length)
  int light_level = int(float(data.sprites_length) * min(max_light_val, 255.0 / 256.0));

  imageStore(
    out_sprite,
    pixel,
    imageLoad(sprites, ivec3(pixel.xy, light_level))
  );
}