using SEED.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// 用于存储每一个instanceID对应的网格的绘制数据
/// </summary>
public struct GrassInfo
{
    public Matrix4x4 localToGround;
    public Vector4 texParams;
}

class GPUInstancePass : ScriptableRenderPass
{
    private GPUInstanceSetting _gpuInstanceSetting;
    public GPUInstancePass(GPUInstanceSetting gpuInstanceSetting)
    {
        _gpuInstanceSetting = gpuInstanceSetting;
    }
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}



