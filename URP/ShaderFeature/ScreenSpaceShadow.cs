   using System;
   using UnityEngine;
   using UnityEngine.Experimental.Rendering;
   using UnityEngine.Rendering;
   using UnityEngine.Rendering.Universal;

   namespace SEED.Rendering
   {
       /// <summary>
       /// 用于收集屏幕空间阴影的Pass
       /// </summary>
       class ScreenSpaceShadowTexPass : ScriptableRenderPass
       {
           private ScreenSpaceShadowSetting _screenSpaceShadowSetting;

           //用handle是因为他能使用string初始化及存储RT的id和identifier
           private RenderTargetHandle _renderTargetHandle;
           private RenderTextureDescriptor _renderTextureDescriptor;
           private Material _material;
           private CommandBuffer cmd;

           internal ScreenSpaceShadowTexPass(ScreenSpaceShadowSetting screenSpaceShadowSetting)
           {
               _material = CoreUtils.CreateEngineMaterial(ShaderPath.screenSpaceShadowPath);
               _screenSpaceShadowSetting = screenSpaceShadowSetting;
               _renderTargetHandle.Init("_ScreenSpaceShadowmapTexture");
           }

           /// <summary>
           /// 用于在摄像机SetUp时更新Shadow设置，只能在AddRenderPass里调用！！！！
           /// ToDo：尚不清楚为什么只能在AddRenderPass里调用ConfigureInput
           /// </summary>
           internal void SetUp()
           {
               //配置该pass的数据输入需求
               ConfigureInput(ScriptableRenderPassInput.Depth);
           }
           
           public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
           {
               _renderTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
               //阴影收集降采样
               _renderTextureDescriptor.width /= _screenSpaceShadowSetting.downSample;
               _renderTextureDescriptor.height /= _screenSpaceShadowSetting.downSample;
               _renderTextureDescriptor.depthBufferBits = 0;
               _renderTextureDescriptor.msaaSamples = 1;
               _renderTextureDescriptor.graphicsFormat =
                   RenderingUtils.SupportsGraphicsFormat(GraphicsFormat.R8_UNorm,
                       FormatUsage.Linear | FormatUsage.Render)
                       ? GraphicsFormat.R8_UNorm
                       : GraphicsFormat.B8G8R8A8_UNorm;

               cmd.GetTemporaryRT(_renderTargetHandle.id, _renderTextureDescriptor, FilterMode.Point);

               //RenderTargetIdentifier renderTargetTexture = _renderTargetHandle.Identifier();
               //设置该pass当前渲染目标
               ConfigureTarget(_renderTargetHandle.Identifier());
               ConfigureClear(ClearFlag.None, Color.white);
           }
           
           public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
           {
               if (_material == null)
               {
                   Debug.LogError("你为什么不看看你的ShaderPath对不对呢？");
                   return;
               }

               cmd = CommandBufferPool.Get("ScreenSpaceShadowCollect");
               //直接画，不需要srcRT
               cmd.Blit(null, _renderTargetHandle.Identifier(), _material);

               CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadows, false);
               CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadowCascades, false);
               CoreUtils.SetKeyword(cmd, "_MAIN_LIGHT_SHADOWS_SCREEN", true);

               context.ExecuteCommandBuffer(cmd);
               CommandBufferPool.Release(cmd);
           }

           public override void OnCameraCleanup(CommandBuffer cmd)
           {
               cmd.ReleaseTemporaryRT(_renderTargetHandle.id);
           }
       }

       /// <summary>
       /// 用于向所有接受阴影的物体广播SSShadow命令
       /// </summary>
       class ScreenSpaceShadowPostPass : ScriptableRenderPass
       {
           private CommandBuffer cmd;
           public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
           {
               ConfigureTarget(BuiltinRenderTextureType.CurrentActive);
           }

           public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
           {
               cmd = CommandBufferPool.Get("ScreenSpaceShadowPostCMD");
               
               ShadowData shadowData = renderingData.shadowData;
               int cascadesCount = shadowData.mainLightShadowCascadesCount;
               bool mainLightShadows = renderingData.shadowData.supportsMainLightShadows;
               bool receiveShadowsNoCascade = mainLightShadows && cascadesCount == 1;
               bool receiveShadowsCascades = mainLightShadows && cascadesCount > 1;

               // Before transparent object pass, force to disable screen space shadow of main light
               CoreUtils.SetKeyword(cmd, "_MAIN_LIGHT_SHADOWS_SCREEN", false);

               // then enable main light shadows with or without cascades
               CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadows, receiveShadowsNoCascade);
               CoreUtils.SetKeyword(cmd, ShaderKeywordStrings.MainLightShadowCascades, receiveShadowsCascades);
               
               context.ExecuteCommandBuffer(cmd);
               CommandBufferPool.Release(cmd);
           }
       }
   }
   