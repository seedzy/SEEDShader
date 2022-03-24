using System.Collections.Generic;
using SEED.Rendering;
using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class ShaderProperties
{
    internal static int obj2World = Shader.PropertyToID("_Obj2World");
    internal static int grassInfos = Shader.PropertyToID("_GrassInfos");
    internal static string HizCSKernal = "CSHizCullingVersionOne";
    //public static int Grass
}

class GPUInstancePass : ScriptableRenderPass
{
    private RenderTargetHandle _hiZBufferRT;
    
    private const string cmdName = "GPUInstance";
    private CommandBuffer _cmd;
    private GPUInstanceSetting _gpuInstanceSetting;
    private Material _material;
    private MaterialPropertyBlock _materialBlock;
    private Transform _groundTran;
    private MeshFilter _groundMF;

    private ComputeBuffer _allPosMatrixBuffer = null;
    private ComputeBuffer _visiblePosMatrixBuffer = null;
    /// <summary>
    /// 用于避免并行计算对同一数组元素的写操作
    /// 也可以用appendStructBuffer处理，但据说用interlocked开销更低
    /// </summary>
    private ComputeBuffer _interLockBuffer = null;
    private uint[] args;
    
    private int hizCSKernelIndex;
    

    public GPUInstancePass(GPUInstanceSetting gpuInstanceSetting)
    {
        _hiZBufferRT.Init("_HiZBufferRT");
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

        if (_gpuInstanceSetting.computeShader != null)
            hizCSKernelIndex = _gpuInstanceSetting.computeShader.FindKernel(ShaderProperties.HizCSKernal);
    }
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (_groundTran == null || _gpuInstanceSetting.instanceMesh == null || _material == null ||
            _gpuInstanceSetting.computeShader == null)
        {
            Debug.LogError("有初始数据为空");
            return;
        }

        
        _cmd = CommandBufferPool.Get(cmdName);
        ComputeShader hizCS = _gpuInstanceSetting.computeShader;

        #region HizCullingFlow

        //强制刷新computeBuffer
        if (_gpuInstanceSetting.rebuildCBuffer)
        {
            ReleaseCullingBuffer();
            _gpuInstanceSetting.rebuildCBuffer = false;
        }
        //ToDo:改成不再引用CS改由CMD托管
        GenerateCullingPosBuffer(_cmd, hizCS);

        if(_gpuInstanceSetting.cullingOn)
            Culling(_cmd, hizCS, renderingData.cameraData);
        
        Debug.LogWarning("visible object count : " + _visiblePosMatrixBuffer.count);
        // _cmd.DrawMeshInstancedIndirect(
        //     _gpuInstanceSetting.instanceMesh, 
        //     0, 
        //     _material, 
        //     0, 
        //     _interLockBuffer, 
        //     0, 
        //     _materialBlock);

        #endregion

        #region directInstance

        // //强制刷新computeBuffer
        // if (_gpuInstanceSetting.rebuildCBuffer)
        // {
        //     InstanceBuffer.Release();
        //     _gpuInstanceSetting.rebuildCBuffer = false;
        // }
        
        // ComputeBuffer cb = InstanceBuffer.GetGrassBuffer(
        //     _groundMF,
        //     _gpuInstanceSetting.maxInstanceCount,
        //     _gpuInstanceSetting.instanceDensity);
        // //将矩阵和Cbuffer(不是那个cbuffer，你懂得)，发送到GPU(就是Shader里)
        // _materialBlock.SetMatrix(ShaderProperties.obj2World, _groundTran.localToWorldMatrix);
        // _materialBlock.SetBuffer(ShaderProperties.grassInfos, cb);
        //
        // _cmd.DrawMeshInstancedProcedural(_gpuInstanceSetting.instanceMesh, 0, _material, 0, InstanceBuffer.InstanceCount, _materialBlock);

        #endregion
        
        
        
        context.ExecuteCommandBuffer(_cmd);
        CommandBufferPool.Release(_cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        //InstanceBuffer.Release();
    }

    /// <summary>
    /// 生成CullingCS所需要的Instance position数据
    /// </summary>
    /// <param name="cs"></param>
    public void GenerateCullingPosBuffer(CommandBuffer cmd, ComputeShader cs)
    {
        if(_allPosMatrixBuffer == null && _visiblePosMatrixBuffer == null && _interLockBuffer == null)
        {
            List<Matrix4x4> allPosList = GetInstanceTransformMatrix(
                _groundMF,
                _gpuInstanceSetting.maxInstanceCount,
                _gpuInstanceSetting.instanceDensity);

            if (allPosList != null)
            {
                _allPosMatrixBuffer = new ComputeBuffer(_gpuInstanceSetting.maxInstanceCount, 16 * 4);
                _allPosMatrixBuffer.SetData(allPosList);

                //TODO:直接创建没剔除大小的buffer合适吗？
                _visiblePosMatrixBuffer = new ComputeBuffer(_gpuInstanceSetting.maxInstanceCount, 16 * 4);

                //args = new uint[] { mesh.GetIndexCount(0), 0, 0, 0, 0 };
                args = new uint[] {1, 0, 0, 0, 0};
                //////////////////////////ComputeBufferType用于标识出特定用途的结构换缓冲区
                //ComputeBufferType.IndirectArguments用于
                //Graphics.DrawProceduralIndirect、ComputeShader.DispatchIndirect
                //或 Graphics.DrawMeshInstancedIndirect 参数的 ComputeBuffer
                _interLockBuffer = new ComputeBuffer(5, sizeof(uint), ComputeBufferType.IndirectArguments);
                _interLockBuffer.SetData(args);
                //发送数据到CS进行剔除操作
                cmd.SetComputeBufferParam(cs, hizCSKernelIndex, "allPosMatrixBuffer", _allPosMatrixBuffer);
                //cmd.SetComputeBufferParam(cs, hizCSKernelIndex, "visiblePosMatrixBuffer", _visiblePosMatrixBuffer);
                cs.SetBuffer(hizCSKernelIndex, "visiblePosMatrixBuffer", _visiblePosMatrixBuffer);
                cmd.SetComputeBufferParam(cs, hizCSKernelIndex, "interLockBuffer", _interLockBuffer);

                _materialBlock.SetMatrix(ShaderProperties.obj2World, _groundTran.localToWorldMatrix);
                _materialBlock.SetBuffer(ShaderProperties.grassInfos, _visiblePosMatrixBuffer);
                Debug.LogWarning("all object count : " + _allPosMatrixBuffer.count);
            }
        }
    }
    
    /// <summary>
    /// 获得Instance对象的obj2World矩阵
    /// </summary>
    /// <param name="ground"></param>
    /// <param name="maxInstanceCount"></param>
    /// <param name="instanceDensity"></param>
    /// <returns></returns>
    public List<Matrix4x4> GetInstanceTransformMatrix(MeshFilter ground, int maxInstanceCount, int instanceDensity)
    {
        List<Matrix4x4> allPosMatrix = null;
        if (ground != null)
        {
            //记录已经实例化的数量
            int count = 0;
            Mesh groundMesh = ground.sharedMesh;
            allPosMatrix = new List<Matrix4x4>();
            
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
                    //构建transformRotationScale矩阵
                    Matrix4x4 transformMatrix = Matrix4x4.TRS(instancePos,
                        Quaternion.FromToRotation(Vector3.up, triFaceNormal) * Quaternion.Euler(0, Random.Range(0, 180), 0), Vector3.one);
                    
                    allPosMatrix.Add(transformMatrix);
                    
                    count++;
                    if (count >= maxInstanceCount)
                        break;
                }
                if (count >= maxInstanceCount)
                    break;
            }
        }
        return allPosMatrix;
    }
    
    public void Culling(CommandBuffer cmd, ComputeShader cs, CameraData camData)
    {
        args[1] = 0;
        _interLockBuffer.SetData(args);

        Camera cam;
        //跳过scene摄像机剔除，方便调试
        if (_gpuInstanceSetting.sceneCullingOn)
        {
            cam = camData.camera;
            cmd.SetComputeMatrixParam(cs, "matrix_VP", camData.GetGPUProjectionMatrix() * cam.worldToCameraMatrix);
        }
        else
        {
            cam = Camera.main;
            cs.SetMatrix("matrix_VP", GL.GetGPUProjectionMatrix(cam.projectionMatrix, false) * cam.worldToCameraMatrix);
        }
        // cmd.SetComputeVectorParam(cs, "camPos", cam.transform.position);
        // cmd.SetComputeVectorParam(cs, "camDir", cam.transform.forward);
        // cmd.SetComputeFloatParam(cs, "camHalfFov", cam.fieldOfView / 2);
        cmd.SetComputeTextureParam(cs, hizCSKernelIndex, "_HiZBufferRT", _hiZBufferRT.Identifier());
        //这里设置线程组数量，160的平方是总的实例化数量， 16是CS里设置的单个线程组中的线程数量
        cmd.DispatchCompute(cs, hizCSKernelIndex, 160 / 16, 160 / 16, 1);
    }

    public void ReleaseCullingBuffer()
    {
        if (_allPosMatrixBuffer != null)
        {
            _allPosMatrixBuffer.Release();
            _allPosMatrixBuffer = null;
        }

        if (_visiblePosMatrixBuffer != null)
        {
            _visiblePosMatrixBuffer.Release();
            _visiblePosMatrixBuffer = null;
        }

        if (_interLockBuffer != null)
        {
            _interLockBuffer.Release();
            _interLockBuffer = null;
        }
    }
    
}

/// <summary>
/// TODO：将会弃用
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

    
}






