using SEED.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class GenerateHiZBufferPass : ScriptableRenderPass
{
    private const int HZBSize = 1024;
    private RenderTextureDescriptor _hzbRTDescriptor;
    private RenderTargetHandle _hzbRTHandle;
    private RenderTargetHandle _tempRTHandle;
    private RenderTargetHandle _historyRTHandle;
    private RenderTargetHandle _depthRTHandle;
    private Material _material;



    /// <summary>
    /// 函数名字面意思
    /// </summary>
    public RenderTextureDescriptor GetHZBRTDescriptor()
    {
        //傻逼unity一个深度图精度变量名还用两种不同的，巴不得有人去看文档是吧
        RenderTextureDescriptor rTDescriptor =
            new RenderTextureDescriptor(HZBSize, HZBSize, RenderTextureFormat.RHalf, 0);
        rTDescriptor.autoGenerateMips = false;
        rTDescriptor.useMipMap = true;
        return rTDescriptor;
    }

    public GenerateHiZBufferPass()
    {
        _hzbRTDescriptor = GetHZBRTDescriptor();
        _hzbRTHandle.Init("HiZBufferRT");
        _tempRTHandle.Init("HZBPassTempRT");
        _historyRTHandle.Init("HZBPassHistoryRT");
        _depthRTHandle.Init("_CameraDepthTexture");
        _material = CoreUtils.CreateEngineMaterial(ShaderPath.GenerateMipMaps);
    }
    
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        cmd.GetTemporaryRT(_hzbRTHandle.id, _hzbRTDescriptor, FilterMode.Point);
        
        ConfigureTarget(_hzbRTHandle.Identifier());
        ConfigureClear(ClearFlag.None, Color.black);
    }
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        CommandBuffer cmd = CommandBufferPool.Get("HiZBuffer");
        int mipMapSize = HZBSize;
        bool isFirstLevel = true;
        int level = 0;
        while (mipMapSize > 8)
        {
            if (isFirstLevel)
            {
                cmd.GetTemporaryRT(_tempRTHandle.id, mipMapSize, mipMapSize, 0, FilterMode.Point,
                    _hzbRTDescriptor.colorFormat);
                // 由管线生成的深度图，需要用作HZB MipMaps的第一级
                cmd.Blit(_depthRTHandle.Identifier(), _tempRTHandle.Identifier());
                isFirstLevel = false;
            }
            else
            {
                cmd.Blit(_historyRTHandle.Identifier(), _tempRTHandle.Identifier(), _material);
            }

            cmd.CopyTexture(_tempRTHandle.Identifier(), 0, 0, _hzbRTHandle.Identifier(), 0, level);
            cmd.Blit(_tempRTHandle.Identifier(), _historyRTHandle.Identifier());

            mipMapSize /= 2;
            level++;
        }


        //}
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    /// <summary>
    /// 在AddRenderPass里调用
    /// 配置该pass的管线数据输入，这里是希望管线提供深度数据
    /// </summary>
    /// <param name="renderer"></param>
    internal void SetUp()
    {
        ConfigureInput(ScriptableRenderPassInput.Depth);
    }
    
    // Cleanup any allocated resources that were created during the execution of this render pass.
    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}



