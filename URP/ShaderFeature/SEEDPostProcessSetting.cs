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
        internal static string GPUInstanceGrass = "SEEDzy/URP/GPUInstance/Grass";
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
        [Header("需要实例化的对象")]
        public Mesh instanceMesh = null;
        [Header("需要实例化指定Mesh的平面")]
        public Transform groundTran = null;
        [Header("最大实例化数量")]
        public int maxInstanceCount = 10000;
        [Header("实例化密度")] 
        public int instanceDensity = 5;

    }
}
