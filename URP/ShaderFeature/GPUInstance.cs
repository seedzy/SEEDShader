using System.Collections.Generic;
using SEED.Rendering;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// 用于存储每一个instanceID对应的网格的绘制数据
/// </summary>
public struct GrassInfo
{
    //4行4列，共16个float，共64byte
    public Matrix4x4 transformMatrix;
    //4个float，共16byte
    public Vector4 transformTex;
}

internal class ShaderProperties
{
    internal static int obj2World = Shader.PropertyToID("_Obj2World");
    internal static int grassInfos = Shader.PropertyToID("_GrassInfos");
    //public static int Grass
}

class GPUInstancePass : ScriptableRenderPass
{
    private const string cmdName = "GPUInstance";
    private CommandBuffer _cmd;
    private GPUInstanceSetting _gpuInstanceSetting;
    private Material _material;
    private MaterialPropertyBlock _materialBlock;
    private Transform _groundTran;
    private MeshFilter _groundMF;

    public GPUInstancePass(GPUInstanceSetting gpuInstanceSetting)
    {
        _gpuInstanceSetting = gpuInstanceSetting;
        _materialBlock = new MaterialPropertyBlock();
        
        if (_gpuInstanceSetting?.groundTran != null)
        {
            _groundTran = _gpuInstanceSetting.groundTran;
            _groundMF = _groundTran.GetComponent<MeshFilter>();
        }
        if (_gpuInstanceSetting.material == null)
        {
            Debug.LogWarning("你确定连个Material都不放吗？");
            _material = CoreUtils.CreateEngineMaterial("Hidden/Universal Render Pipeline/FallbackError");
        }
        else
            _material = _gpuInstanceSetting.material;
    }
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if(_groundTran == null || _gpuInstanceSetting.instanceMesh == null || _material == null)
            return;
        
        _cmd = CommandBufferPool.Get(cmdName);
        
        //强制刷新computeBuffer
        if (_gpuInstanceSetting.rebuildCBuffer)
        {
            InstanceBuffer.Release();
            _gpuInstanceSetting.rebuildCBuffer = false;
        }
        
        ComputeBuffer cb = InstanceBuffer.GetGrassBuffer(
            _groundMF,
            _gpuInstanceSetting.maxInstanceCount,
            _gpuInstanceSetting.instanceDensity);
        //将矩阵和Cbuffer(不是那个cbuffer，你懂得)，发送到GPU(就是Shader里)
        _materialBlock.SetMatrix(ShaderProperties.obj2World, _groundTran.localToWorldMatrix);
        _materialBlock.SetBuffer(ShaderProperties.grassInfos, cb);
        
        _cmd.DrawMeshInstancedProcedural(_gpuInstanceSetting.instanceMesh, 0, _material, 0, InstanceBuffer.InstanceCount, _materialBlock);
        
        context.ExecuteCommandBuffer(_cmd);
        CommandBufferPool.Release(_cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        //InstanceBuffer.Release();
    }
}

/// <summary>
/// 记录所有实例化对象类型的ComputeBuffer
/// </summary>
class InstanceBuffer
{
    private static int instancedCount;
    private static ComputeBuffer grassBuffer = null;

    /// <summary>
    /// 不要乱调啊，在你不想再Instance之前不要清除ComputeBuffer
    /// </summary>
    public static void Release()
    {
        if (grassBuffer != null)
        {
            grassBuffer.Release();
            grassBuffer = null;
        }
    }

    /// <summary>
    /// 获取当前实例化对象数量，暂时这样写，后面可能会改？
    /// </summary>
    public static int InstanceCount
    {
        get
        {
            return instancedCount;
        }
    }

    public static ComputeBuffer GetGrassBuffer2(MeshFilter ground, int maxInstanceCount, int instanceDensity)
    {
        if (grassBuffer == null && ground != null)
        {
            //记录已经实例化的数量
            int count = 0;
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
                float triInstanceCount = (int)Mathf.Max(1,triArea * instanceDensity);
                //计算当前三角的面法线，使实例化对象能与生成平面垂直
                Vector3 triFaceNormal = SEED.Math.GetFaceNormal(v1, v2, v3);
                
                for (int j = 0; j < triInstanceCount; j++)
                {
                    Vector3 instancePos = SEED.Math.RandomPointInsideTriangle(v1, v2, v3);
                    Vector4 transformTex = Vector4.one;
                    //构建transformRotationScale矩阵
                    Matrix4x4 transformMatrix = Matrix4x4.TRS(instancePos,
                        Quaternion.FromToRotation(Vector3.up, triFaceNormal) * Quaternion.Euler(0, Random.Range(0, 180), 0), Vector3.one);
                    
                    GrassInfo grassInfo = new GrassInfo()
                    {
                        transformMatrix = transformMatrix,
                        transformTex = transformTex
                    };
                    grassInfos.Add(grassInfo);
                    count++;
                    if (count >= maxInstanceCount)
                        break;
                }
                if (count >= maxInstanceCount)
                    break;
            }

            if(grassInfos.Count >= 1)
                Debug.LogWarning(grassInfos[0].transformMatrix);
            instancedCount = count;
            grassBuffer = new ComputeBuffer(instancedCount, 64 + 16);
            grassBuffer.SetData(grassInfos);
        }
        return grassBuffer;
    }
    public static ComputeBuffer GetGrassBuffer(MeshFilter ground, int maxInstanceCount, int instanceDensity)
    {
        if (grassBuffer == null && ground != null)
        {
            //记录已经实例化的数量
            int count = 0;
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
                float triInstanceCount = (int)Mathf.Max(1,triArea * instanceDensity);
                //计算当前三角的面法线，使实例化对象能与生成平面垂直
                Vector3 triFaceNormal = SEED.Math.GetFaceNormal(v1, v2, v3);
                
                for (int j = 0; j < triInstanceCount; j++)
                {
                    Vector3 instancePos = SEED.Math.RandomPointInsideTriangle(v1, v2, v3);
                    Vector4 transformTex = Vector4.one;
                    //构建transformRotationScale矩阵
                    Matrix4x4 transformMatrix = Matrix4x4.TRS(instancePos,
                        Quaternion.FromToRotation(Vector3.up, triFaceNormal) * Quaternion.Euler(0, Random.Range(0, 180), 0), Vector3.one);
                    
                    GrassInfo grassInfo = new GrassInfo()
                    {
                        transformMatrix = transformMatrix,
                        transformTex = transformTex
                    };
                    grassInfos.Add(grassInfo);
                    count++;
                    if (count >= maxInstanceCount)
                        break;
                }
                if (count >= maxInstanceCount)
                    break;
            }

            if(grassInfos.Count >= 1)
                Debug.LogWarning(grassInfos[0].transformMatrix);
            instancedCount = count;
            grassBuffer = new ComputeBuffer(instancedCount, 64 + 16);
            grassBuffer.SetData(grassInfos);
        }
        return grassBuffer;
    }
}






