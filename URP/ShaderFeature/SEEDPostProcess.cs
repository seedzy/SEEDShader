using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;
using UnityEditor;
using SEED.Rendering;
using Sirenix.OdinInspector;
using UnityEngine.Experimental.Rendering;
using DepthOfFieldSetting = SEED.Rendering.DepthOfFieldSetting;



public class SEEDPostProcess : ScriptableRendererFeature
{ 
    
    [Toggle("enable"),              GUIColor(0.8f,0.85f,1)]
   public ScreenSpaceShadowSetting screenSpaceShadowSetting = new ScreenSpaceShadowSetting();

   [Toggle("enable"), GUIColor(0.8f, 0.85f, 1)]
   public ToneMappingSetting toneMappingSetting     = new ToneMappingSetting();
   [Toggle("enable"),               GUIColor(0.8f,0.85f,1)]
   public SEED.Rendering.BloomSetting bloom          = new SEED.Rendering.BloomSetting();
   [Toggle("enable"),               GUIColor(0.8f,0.85f,1)]
   public SEED.Rendering.GaussianSetting gaussian    = new SEED.Rendering.GaussianSetting();
   [Toggle("enable"),               GUIColor(0.8f,0.85f,1)]
   public DepthOfFieldSetting depthOfField           = new DepthOfFieldSetting();
   [Toggle("enable"),               GUIColor(0.8f,0.85f,1)]
   public GPUInstanceSetting gpuInstanceSetting      = new GPUInstanceSetting();
   
   class SEEDPostProcessPass : ScriptableRenderPass
    {
        private RenderTargetIdentifier _src;
        private RenderTargetIdentifier _dis;
        private RenderTargetHandle _TempRT;
        private Material _material;
        private ToneMappingSetting _toneMappingSetting;

        public SEEDPostProcessPass()
        {
            _TempRT.Init("TempRT");
            _material = CoreUtils.CreateEngineMaterial(ShaderPath.PostProcess);
        }
        
        public void SetUp(RenderTargetIdentifier src, RenderTargetIdentifier dis, ToneMappingSetting toneMappingSetting)
        {
            _src = src;
            _dis = dis;
            _toneMappingSetting = toneMappingSetting;
        }
        //SEEDPostProcessPass
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor camRTDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(_TempRT.id, camRTDescriptor);
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("SEEDPostProcess");
            _material.SetFloat("_Expossure", _toneMappingSetting.Expossure);
            cmd.Blit(_src, _TempRT.Identifier(), _material);
            cmd.Blit(_TempRT.Identifier(), _dis);
            
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            
        }
    }
    
   private SEEDPostProcessPass       PPPass                 = null;
   private ScreenSpaceShadowTexPass  SSShadow               = null;
   private ScreenSpaceShadowBlur     SSBlur                 = null;
   private ScreenSpaceShadowPostPass SSShadowPost           = null;
   private GPUInstancePass           GPUInstancePass        = null;
   private GenerateHiZBufferPass     GenerateHiZBufferPass  = null;
   private RenderTargetHandle m_AfterPostProcessColor;


   /// <summary>
   /// 会在ShaderFeature第一次初始化时调用，早于AddRenderPass
   /// </summary>
   public override void Create()
   {
       if (screenSpaceShadowSetting.enable)
       {
           //ScreenSpaceShadowTexPass
           SSShadow = new ScreenSpaceShadowTexPass(screenSpaceShadowSetting);
           SSShadow.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;
           if(screenSpaceShadowSetting.GaussianSoftShadow) 
               SSBlur = new ScreenSpaceShadowBlur(SSShadow.GetShadowRenderTextureHandle());
           SSBlur.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;
           SSShadowPost = new ScreenSpaceShadowPostPass();
           SSShadowPost.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
       }

       if (gpuInstanceSetting.enable)
       {
           GPUInstancePass = new GPUInstancePass(gpuInstanceSetting);
           //注意！！即便使用GPUInstance托管实例化，依然受到硬件Early-Z优化，当Instance数量过大是有较为明显优化，
           //因此把instance延迟到opaque之后，进行剔除
           //TODO:失策了，是我在放屁。。。想多了，放什么时候都一样
           GPUInstancePass.renderPassEvent = gpuInstanceSetting.renderPassEvent;
       }

       GenerateHiZBufferPass = new GenerateHiZBufferPass();
       GenerateHiZBufferPass.renderPassEvent = RenderPassEvent.AfterRenderingPrePasses;
       //PostProcessMainPass
       PPPass = new SEEDPostProcessPass();
       PPPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
   }

   /// <summary>
   /// 会在摄像机每次SetUp时调用，晚于Create
   /// ToDo：尚不清楚摄像机SetUp的间隔(时机)
   /// </summary>
   /// <param name="renderer"></param>
   /// <param name="renderingData"></param>
   public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
   {
       
       
       
       if (screenSpaceShadowSetting.enable)
       {
           bool allowMainLightShadows = renderingData.shadowData.supportsMainLightShadows && renderingData.lightData.mainLightIndex != -1;
           if (allowMainLightShadows)
           {
               SSShadow.SetUp();
               renderer.EnqueuePass(SSShadow);
               if(screenSpaceShadowSetting.GaussianSoftShadow) 
                   renderer.EnqueuePass(SSBlur);
               renderer.EnqueuePass(SSShadowPost);
           }
       }
       
       renderer.EnqueuePass(GenerateHiZBufferPass);

       if (gpuInstanceSetting.enable)
       {
           renderer.EnqueuePass(GPUInstancePass);
       }
       else
       {
           //ToDo：暂时不知道单个renderFeature的结束事件，先在这释放cbuffer
           //InstanceBuffer.Release();
           GPUInstancePass?.ReleaseCullingBuffer();
       }

       if (toneMappingSetting.enable)
       {
           //m_AfterPostProcessColor.Init("_AfterPostProcessTexture");
           //var sourceForFinalPass = (renderingData.cameraData.postProcessEnabled) ? m_AfterPostProcessColor : RenderTargetHandle.CameraTarget;
           PPPass.SetUp(renderer.cameraColorTarget, RenderTargetHandle.CameraTarget.Identifier(), toneMappingSetting);
           renderer.EnqueuePass(PPPass);
       }
   }

   protected override void Dispose(bool disposing)
   {
       base.Dispose(disposing);
       GPUInstancePass?.ReleaseCullingBuffer();
   }

   private void OnDestroy()
   {
       GPUInstancePass?.ReleaseCullingBuffer();
   }

   private void OnDisable()
   {
       GPUInstancePass?.ReleaseCullingBuffer();
   }
}


