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
        _hzbRTHandle.Init("_HiZBufferRT");
        _tempRTHandle.Init("_HZBPassTempRT");
        _historyRTHandle.Init("_HZBPassHistoryRT");
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
        
        // using (new ProfilingScope(cmd, Profiling.internalStartRendering))
        // {
        
        int mipMapSize = HZBSize;
        bool isFirstLevel = true;
        int level = 0;
        while (mipMapSize > 8)
        {
            cmd.GetTemporaryRT(_tempRTHandle.id, mipMapSize, mipMapSize, 0, FilterMode.Point,
                _hzbRTDescriptor.colorFormat);

            if (isFirstLevel)
            {
                // 由管线生成的深度图，需要用作HZB MipMaps的第一级
                cmd.Blit(_depthRTHandle.Identifier(), _tempRTHandle.Identifier());
                isFirstLevel = false;
            }
            else
            {
                cmd.Blit(_historyRTHandle.Identifier(), _tempRTHandle.Identifier(), _material);
                //这里history需要用于保存上下一级的mipmap，所以这里在传递完上一级mipmap后需要释放并创建下级分辨率的rt
                //如果是直接使用rendertexture类创建rt的话，直接传引用就好了，但是这样创建的rt没办法和cmd创建的rt混合使用，暂时只能先这样写了
                cmd.ReleaseTemporaryRT(_historyRTHandle.id);
            }

            cmd.CopyTexture(_tempRTHandle.Identifier(), 0, 0, _hzbRTHandle.Identifier(), 0, level);
            cmd.GetTemporaryRT(_historyRTHandle.id, mipMapSize, mipMapSize, 0, FilterMode.Point,
                _hzbRTDescriptor.colorFormat);
            cmd.Blit(_tempRTHandle.Identifier(), _historyRTHandle.Identifier());


            cmd.ReleaseTemporaryRT(_tempRTHandle.id);
            mipMapSize /= 2;
            level++;
        }

        
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



