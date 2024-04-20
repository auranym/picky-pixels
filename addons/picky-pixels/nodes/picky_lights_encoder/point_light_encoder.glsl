#[compute]
#version 450

// --------------------------------------------------------
// This shader is run for EVERY point light.
// It takes a point light's data and converts it into a
// single integer 0-255, representing how much light
// the point light contributes at a pixel.
//
// This int is applied to the output image via imageAtomicMax.
// Thus, when doing this for every single point light, we
// have a single uint r32 image encoding the lighting for that
// frame.
//
// The resulting image is used by PickySprite2Ds for decoding.
// --------------------------------------------------------

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// Output image that is the encoded light texture.
layout(r32ui, set = 0, binding = 0) uniform uimage2D out_tex;

// Output image's data
layout(set = 0, binding = 1, std430) restrict readonly buffer OutputData {
  ivec2 pos;
}
output_data;

// Input image used by the point light
layout(rgba32f, set = 0, binding = 2) restrict readonly uniform image2D light_tex;

// Other input data
layout(set = 0, binding = 3, std430) restrict readonly buffer LightData {
  ivec2 pos;
}
light_data;

void main() {
  ivec2 local_pixel = ivec2(gl_GlobalInvocationID.xy);
  vec4 color = imageLoad(light_tex, local_pixel);
  // Find the average of the color channels,
  // then convert it to a uint ranging 0-255.
  uint light = min(uint(255.0 * (color.r + color.g + color.b) / 3.0), 255);
  imageAtomicMax(
    out_tex,
    local_pixel - output_data.pos + light_data.pos,
    light
  );
}