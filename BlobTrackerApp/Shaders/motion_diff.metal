#include <metal_stdlib>
using namespace metal;

kernel void motion_diff(
    texture2d<float, access::read> currentTexture [[texture(0)]],
    texture2d<float, access::read> previousTexture [[texture(1)]],
    texture2d<float, access::write> outputTexture [[texture(2)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }

    float currentLuma = dot(currentTexture.read(gid).rgb, float3(0.299, 0.587, 0.114));
    float previousLuma = dot(previousTexture.read(gid).rgb, float3(0.299, 0.587, 0.114));
    float diff = abs(currentLuma - previousLuma);
    outputTexture.write(float4(diff, diff, diff, 1.0), gid);
}
