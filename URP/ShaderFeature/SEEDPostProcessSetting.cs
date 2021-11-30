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
        public bool screenSpaceFogOn = false;
    }
    
    [Serializable]
    public class BloomSetting
    {
        public bool bloomOn = false;
    }
    
    [Serializable]
    public class GaussianSetting
    {
        public bool gaussianOn = false;
    }
    
    [Serializable]
    public class DepthOfFieldSetting
    {
        public bool depthOfFieldOn = false;
    }
    
    [Serializable]
    public class VolumeCloudSetting
    {
        public bool volumeCloudOn = false;
    }
}
