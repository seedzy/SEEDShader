// using System.Collections;
// using System.Collections.Generic;
// using System.Runtime.InteropServices;
// using UnityEditor;
// using UnityEngine;
//
// [CustomEditor(typeof(SEEDPostProcess))]
// public class SEEDPostProcessEditor : Editor
// {
//     #region Serialized Properties
//
//     private SerializedProperty _SSShadowOn;
//
//     #endregion
//
//     private bool _IsInitialized = false;
//
//     #region SPPEditorStyle
//     private struct GUIStyl
//     {
//         //public static GUIContent 
//     }
//     #endregion
//     
//     private void Init()
//     {
//         SerializedProperty sppSetting = serializedObject.FindProperty("_sppSetting");
//         _SSShadowOn = sppSetting.FindPropertyRelative("screenSpaceShadowOn");
//         _IsInitialized = true;
//     }
//
//     private bool _isSSShadowFoldout = false; 
//     
//     //private GUIStyle moFoldout = EditorStyles.foldoutHeader;
//
//     public override void OnInspectorGUI()
//     {
//         if(!_IsInitialized)
//             Init();
//         //绘制sshadow折叠栏
//         _isSSShadowFoldout = EditorGUILayout.Foldout(_isSSShadowFoldout, "ScreenSpaceShadow");
//         _isSSShadowFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(_isSSShadowFoldout, "ScreenSpaceShadow", EditorStyles.foldoutHeader);
//         //EditorGUILayout.Foldout()
//         if (_isSSShadowFoldout)
//         {
//             EditorGUILayout.PropertyField(_SSShadowOn, new GUIContent("ScreenSpaceShadow"));
//         }
//         EditorGUILayout.EndFoldoutHeaderGroup();
//     }
//     
// }
