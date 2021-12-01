using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SEED
{
    public class Math{
    
        /// <summary>
        /// 输入三点坐标，返回三角形面积
        /// </summary>
        /// <param name="p1"></param>
        /// <param name="p2"></param>
        /// <param name="p3"></param>
        /// <returns></returns>
        public static float GetAreaOfTriangle(Vector3 p1,Vector3 p2,Vector3 p3){
            var vx = p2 - p1;
            var vy = p3 - p1;
            var dotvxy = Vector3.Dot(vx,vy);
            var sqrArea = vx.sqrMagnitude * vy.sqrMagnitude -  dotvxy * dotvxy;
            return 0.5f * Mathf.Sqrt(sqrArea);
        }
        
        /// <summary>
        /// 输入三点坐标，返回对应三角形面法线
        /// </summary>
        /// <param name="p1"></param>
        /// <param name="p2"></param>
        /// <param name="p3"></param>
        /// <returns></returns>
        public static Vector3 GetFaceNormal(Vector3 p1,Vector3 p2,Vector3 p3){
            var vx = p2 - p1;
            var vy = p3 - p1;
            return Vector3.Cross(vx,vy);
        }
        
        /// <summary>
        /// 三角形内部，取平均分布的随机点
        /// </summary>
        public static Vector3 RandomPointInsideTriangle(Vector3 p1,Vector3 p2,Vector3 p3){
            var x = Random.Range(0,1f);
            var y = Random.Range(0,1f);
            if(y > 1 - x){
                //如果随机到了右上区域，那么反转到左下
                var temp = y;
                y = 1 - x;
                x = 1 - temp;
            }
            var vx = p2 - p1;
            var vy = p3 - p1;
            return p1 + x * vx + y * vy;
        }
    }
}

