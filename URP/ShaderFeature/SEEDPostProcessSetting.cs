using System;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using Sirenix.OdinInspector;
using Sirenix.Serialization;
using UnityEngine;
using UnityEngine.Rendering;

namespace SEED.Rendering
{
    #region ShaderPath
    internal struct ShaderPath
    {
        internal static string screenSpaceShadowPath = "Hidden/Universal Render Pipeline/ScreenSpaceShadows";
    }
    #endregion
    
    
    
    
    [Serializable]
    public class ScreenSpaceShadowSetting
    {
        public bool enable = false;
        [Range(1, 10)]
        public int downSample = 1;
        
        public ScreenSpaceShadowSetting()
        {
            //material = CoreUtils.CreateEngineMaterial(ShaderPath.screenSpaceShadow);
        }
        
    }

    [Serializable]
    public class ScreenSpaceFogSetting
    {
        public bool enable = false;
    }
    
    [Serializable]
    public class BloomSetting
    {
        public bool enable = false;
    }
    
    [Serializable]
    public class GaussianSetting
    {
        public bool enable = false;
    }
    
    [Serializable]
    public class DepthOfFieldSetting
    {
        public bool enable = false;
    }
    
    [Serializable]
    public class VolumeCloudSetting
    {
        public bool enable = false;
    }
    
    [Serializable]
    public class GPUInstanceSetting
    {
        public bool enable = false;
        [Header("Instance对象")]
        public Mesh instanceObj = null;
        [Header("需要Instance指定Mesh的平面")]
        public Mesh ground = null;
    }
}
