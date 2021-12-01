using System.Collections.Generic;
using SEED.Rendering;
using Sirenix.OdinInspector.Editor.Validation;
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

/// <summary>
/// 记录所有实例化对象类型的ComputeBuffer
/// </summary>
class InstanceBuffer
{
    private static ComputeBuffer grassBuffer = null;

    public static ComputeBuffer GetGrassBuffer(MeshFilter ground, Matrix4x4 obj2World, int instanceDensity)
    {
        if (grassBuffer == null)
        {
            Mesh groundMesh = ground.sharedMesh;
            List<GrassInfo> grassInfos = new List<GrassInfo>();
            
            //triangles记录的是三角形各顶点在mesh顶点数组中的序号，并且是连续的012为第一个三角形。。。。。
            var triVerIndexs = groundMesh.triangles;
            //获取mesh顶点数组
            var vertices = groundMesh.vertices;
            
            for (int i = 0; i < triVerIndexs.Length / 3; i++)
            {
                #region 收集三角形三个顶点的位置信息(可用于计算三角形表面法线等等,向量叉乘难道不会吗)
                var index1 = triVerIndexs[i * 3];
                var index2 = triVerIndexs[i * 3 + 1];
                var index3 = triVerIndexs[i * 3 + 2];
                var v1 = vertices[index1];
                var v2 = vertices[index2];
                var v3 = vertices[index3];
                #endregion

                //计算当前三角内的实例化数量
                float triArea = SEED.Math.GetAreaOfTriangle(v1, v2, v3);
                int instanceCount = (int)Mathf.Max(1,triArea * instanceDensity);

                //计算当前三角的面法线，使实例化对象能与生成平面垂直
                Vector3 triFaceNormal = SEED.Math.GetFaceNormal(v1, v2, v3);
                for (int j = 0; j < instanceCount; j++)
                {
                    Vector3 instancePos = SEED.Math.RandomPointInsideTriangle(v1, v2, v3);
                    Vector4 transformTex = Vector4.one;
                    Matrix4x4 transformMatrix = Matrix4x4.TRS(instancePos,
                        Quaternion.Euler(0, Random.Range(0, 180), 0) * triFaceNormal, Vector3.one);
                }

            }
        }
        return grassBuffer;
    }
}






