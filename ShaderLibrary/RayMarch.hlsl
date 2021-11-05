#ifndef SEED_RAYMARCH
#define SEED_RAYMARCH

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/Shader/SEEDShader/ShaderLibrary/Common.hlsl"

#define E 2.71

/// <summary>
/// beers-law定律
/// </summary>
/// <param name="distance">穿透的介质厚度</param>
/// <param name="attenuation">对光线的衰减率</param>
/// <returns>光线透射率</returns>
half BeersLaw(half distance, half attenuation)
{
    //optical depth(光深度)
    //原本光深度应该对光衰减率函数在两点间distance上积分获得，但是由于放在计算机中运算，衰减率在获得的时候已经是常量了，因此
    //因此积分直接简化为：
    //假设这个常数为C，积分区域为【a，b】
    //那么∫【a→b】Cdx
    //=Cx【a→b】
    //=C(b-a)
    //数学真tm好
    half depth = distance * attenuation;
    return pow(E, depth);
}


/// <summary>
/// 传入 ，边界框最小值 ，边界框最大值 ，世界相机位置，反向世界空间光线方向，
/// </summary>
/// <returns>会返回一个Float2 相机到容器的距离 & 返回光线是否在容器中(光线出射和入射间的距离) & dstA&dstB(还不知道具体含义)</returns>
float4 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 invRaydir) 
{
    float3 t0 = (boundsMin - rayOrigin) * invRaydir;
    float3 t1 = (boundsMax - rayOrigin) * invRaydir;
    float3 tmin = min(t0, t1);
    float3 tmax = max(t0, t1);

    float dstA = max(max(tmin.x, tmin.y), tmin.z); //进入点
    float dstB = min(tmax.x, min(tmax.y, tmax.z)); //出去点

    //光线源到box上光线入射点距离，当光线源在box内部时返回0
    float disCamWithBox = max(0, dstA);
    //描述光线出射和入射间的距离，也就是box内的步进距离，若为0说明光线并未进入包围盒
    float dstInsideBox = max(0, dstB - disCamWithBox);
    return float4(disCamWithBox, dstInsideBox, dstA, dstB);
}

/// <summary>
/// 指数级密度增长
/// </summary>
/// <param name="distance">介质厚度</param>
/// <param name="attenuation">线性密度</param>
/// <returns>指数密度</returns>
float ExponentialDensity(float depth, float density)
{
    if(depth > 0)
        return 1/pow(2.71, depth * density);
    return 1;
}


/// <summary>
/// 对heightMap进行光线步进
/// </summary>
/// <param name="startZ">heightMap的起始高度</param>
/// <param name="numSteps">最大步进次数</param>
/// <param name="stepSize">单次步进长度</param>
/// <param name="traceVec">步进方向矢量(由单位方向向量 * stepSize)</param>
/// <param name="finalStepTraceVec">heightMap的起始高度</param>
/// <param name="finalStepSize">heightMap的起始高度</param>
/// <param name="bias">步进起始点</param>
/// <param name="heightScale">heightMap的起始高度</param>
/// <param name="temporalJitter">是否对步进方向进行时间性扰动</param>
/// <param name="threshold">heightMap的起始高度</param>
/// <param name="heightMapChannel">指定存储高度数据的通道，默认为r</param>
/// <returns>返回光线在该该方向heightMap构成容器内的步进距离</returns>
float RayMarchHeightMap(
    TEXTURE2D_PARAM(_HeightMap, sampler_HeightMap),
    float2 uv,
    float startZ,
    float numSteps,
    float stepSize,
    float3 traceVec,
    half bias,
    half heightScale,
    bool temporalJitter,
    half threshold,
    half4 heightMapChannel = half4(1,0,0,0)
    )
{
    if(startZ <= threshold)
        return 0;
    half TimeLerp = 1;
    half DepthDiff = 0;
    half LastDiff = -bias;

    //We scale Z by 2 since the heightmap represents two halves of as symmetrical volume texture, split along Z where texture = 0
    //将高度图沿Z轴对称扩展，并将其视为3DTexture
    float3 RayStepUVz = float3(traceVec.x, traceVec.y, traceVec.z*2);

    //记录步进总距离
    float accum = 0;
    
    float3 RayUVz = float3(uv, startZ);


    // if(temporalJitter)
    // {
    //     // jitter the starting position
    //     int3 randpos = int3(Parameters.SvPosition.xy, View.StateFrameIndexMod8);
    //     float rand = float(Rand3DPCG16(randpos).x) / 0xffff;
    //     RayUVz += RayStepUVz * rand;
    // }

    int i = 0;
    [unroll(64)]while (i < numSteps)
    {

        RayUVz += RayStepUVz;
        //确保步进不超出纹理UV范围
        RayUVz.xy = saturate(RayUVz.xy);
        float SampleDepth = dot(heightMapChannel, SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, RayUVz.xy));
        DepthDiff = abs(RayUVz.z) - abs(SampleDepth);


        if (DepthDiff <= 0)
        {

            if(LastDiff > 0)
            {
                TimeLerp = saturate( LastDiff / (LastDiff - DepthDiff));
                accum += stepSize * (1-TimeLerp);
                //accum+=StepSize;
            }
            else
            {
                accum+=stepSize;
            }
        }
        else
            if(LastDiff <= 0)
            {
                TimeLerp = saturate( LastDiff / (LastDiff - DepthDiff));
                accum += stepSize * (TimeLerp);
                //accum+=StepSize;
            }

        LastDiff = DepthDiff;

        i++;
    }


    //Run one more iteration outside of the loop. Using the Box Intersection in the material graph, we precompute the number of whole steps that can be run which leaves one final 'short step' which is the remainder that is traced here. This was cheaper than checking or clamping the UVs inside of the loop.
    RayUVz += RayStepUVz;
    RayUVz.xy = saturate(RayUVz.xy);
    float SampleDepth = dot( heightMapChannel, SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, RayUVz.xy));
    DepthDiff = abs(RayUVz.z) - abs(SampleDepth);


    if (DepthDiff <= 0)
    {
        accum+=stepSize;
    }
    else
        if(LastDiff <= 0)
        {
            TimeLerp = saturate( LastDiff / (LastDiff - DepthDiff));
            accum += stepSize * (TimeLerp);
        }

    return accum;
}

/// <summary>
/// 光步2D云
/// </summary>
/// <param name="TEXTURE2D_PARAM">高度图及其采样器</param>
/// <param name="uv">就是uv嘛</param>
/// <param name="lightDirTS">切线空间下光照方向</param>
/// <param name="maxSteps">最大步进次数</param>
/// <param name="attenuation">光线衰减率</param>
/// <param name="startBias">步进起始点偏移</param>
/// <param name="heightScale">heightMap的起始高度</param>
/// <param name="traceDistance">光线步进的最大距离(2D云有uv限制，不要超过1)</param>
/// <param name="temporalJitter">是否对步进方向进行时间性扰动</param>
/// <param name="heightMapChannel">指定存储高度数据的通道，默认为r</param>
/// <returns>float2(光线, 高度图采样数据)</returns>
float2 RayMarch2DCloud(
    TEXTURE2D_PARAM(_CloudHeightMap, sampler_CloudHeightMap),
    float2 uv,
    float3 lightDirTS,
    int maxSteps = 64,
    half attenuation = 8.0,
    half startBias = 0.05,
    half heightScale = 1.0,
    half traceDistance = 1.0,
    bool temporalJitter = true,
    half4 heightMapChannel = half4(1,0,0,0)
    )
{
    lightDirTS = normalize(lightDirTS);
    half3 lightVectorTS = lightDirTS * traceDistance;

    float height = dot(SAMPLE_TEXTURE2D(_CloudHeightMap, sampler_CloudHeightMap, uv), heightMapChannel);
    float heightReturn = height;
    
    height *= (1- startBias);
    float3 rayOrigin = float3(frac(uv), height);
    //由高度图模拟的包围盒求交
    float4 rayBoxReturn = rayBoxDst(0, 1, rayOrigin, 1/lightVectorTS);
    //独立出1/减少运算
    half oneDivMaxSteps = 1/maxSteps;
    //How many Steps Fit to edge
    half steps2BoxEdge = rayBoxReturn.w * maxSteps;
    half numSteps = min(floor(steps2BoxEdge), maxSteps);
    half stepSize = oneDivMaxSteps * traceDistance;
    //单步光线步进矢量
    half3 lightStepVectorTS = lightVectorTS * oneDivMaxSteps;
    
    half lightRayDis = RayMarchHeightMap(
        _CloudHeightMap, sampler_CloudHeightMap,
        frac(uv),
        height,
        numSteps,
        stepSize,
        lightStepVectorTS,
        1 - startBias,
        heightScale,
        temporalJitter,
        0,
        heightMapChannel
        );
    return float2(BeersLaw(lightRayDis, attenuation), heightReturn);
}

#endif