#include <metal_stdlib>
using namespace metal;

kernel void edge_detect(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }

    float4 color = inputTexture.read(gid);
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
    outputTexture.write(float4(luma, luma, luma, 1.0), gid);
}
