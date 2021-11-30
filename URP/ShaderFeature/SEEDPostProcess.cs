using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;
using UnityEditor;
using SEED.Rendering;
using Sirenix.OdinInspector;
using UnityEngine.Experimental.Rendering;
using DepthOfField = SEED.Rendering.DepthOfFieldSetting;



public class SEEDPostProcess : ScriptableRendererFeature
{ 
    
    [Toggle("enable"), GUIColor(0.8f,0.85f,1)]
   public ScreenSpaceShadowSetting screenSpaceShadowSetting = new ScreenSpaceShadowSetting();
   [Toggle("bloomOn"),             GUIColor(0.8f,0.85f,1)]
   public SEED.Rendering.BloomSetting bloom          = new SEED.Rendering.BloomSetting();
   [Toggle("gaussianOn"),          GUIColor(0.8f,0.85f,1)]
   public SEED.Rendering.GaussianSetting gaussian    = new SEED.Rendering.GaussianSetting();
   [Toggle("depthOfFieldOn"),      GUIColor(0.8f,0.85f,1)]
   public DepthOfField depthOfField           = new DepthOfField();
   
   class SEEDPostProcessPass : ScriptableRenderPass
    {
        internal ScreenSpaceShadowSetting _screenSpaceShadowSetting;

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

   private ScreenSpaceShadowTexPass  SSShadow     = null;
   private ScreenSpaceShadowPostPass SSShadowPost = null;
   private SEEDPostProcessPass       PPPass       = null;


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

           SSShadowPost = new ScreenSpaceShadowPostPass();
           SSShadowPost.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
       }
       //PostProcessMainPass
       PPPass = new SEEDPostProcessPass();
       PPPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
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
               renderer.EnqueuePass(SSShadowPost);
           }
       }
   }
       
}

