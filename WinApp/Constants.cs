namespace VTubeLink
{
    public static class Constants
    {
        public static readonly string[] BlendshapeNames = [
            "eyeLookIn_L", "eyeLookOut_L", "eyeLookDown_L", "eyeLookUp_L", "eyeBlink_L", "eyeSquint_L", "eyeWide_L",
            "eyeLookIn_R", "eyeLookOut_R", "eyeLookDown_R", "eyeLookUp_R", "eyeBlink_R", "eyeSquint_R", "eyeWide_R",
            "browDown_L", "browOuterUp_L", "browDown_R", "browOuterUp_R", "browInnerUp",
            "noseSneer_L", "noseSneer_R",
            "cheekSquint_L", "cheekSquint_R", "cheekPuff",
            "mouthLeft", "mouthDimple_L", "mouthFrown_L", "mouthLowerDown_L", "mouthPress_L", "mouthSmile_L", "mouthStretch_L", "mouthUpperUp_L",
            "mouthRight", "mouthDimple_R", "mouthFrown_R", "mouthLowerDown_R", "mouthPress_R", "mouthSmile_R", "mouthStretch_R", "mouthUpperUp_R",
            "mouthClose", "mouthFunnel", "mouthPucker", "mouthRollLower", "mouthRollUpper", "mouthShrugLower", "mouthShrugUpper",
            "jawLeft", "jawRight", "jawForward", "jawOpen",
            "tongueOut"
        ];
        
        public static readonly string[] CustomParams = [
            "EyeBlinkLeft", "EyeLookDownLeft", "EyeLookInLeft", "EyeLookOutLeft", "EyeLookUpLeft", "EyeSquintLeft", "EyeWideLeft",
            "EyeBlinkRight", "EyeLookDownRight", "EyeLookInRight", "EyeLookOutRight", "EyeLookUpRight", "EyeSquintRight", "EyeWideRight",
            "JawForward", "JawLeft", "JawRight", "JawOpen",
            "MouthClose", "MouthFunnel", "MouthPucker", "MouthLeft", "MouthRight", "MouthSmileLeft", "MouthSmileRight",
            "MouthFrownLeft", "MouthFrownRight", "MouthDimpleLeft", "MouthDimpleRight", "MouthStretchLeft", "MouthStretchRight",
            "MouthRollLower", "MouthRollUpper", "MouthShrugLower", "MouthShrugUpper", "MouthPressLeft", "MouthPressRight",
            "MouthLowerDownLeft", "MouthLowerDownRight", "MouthUpperUpLeft", "MouthUpperUpRight",
            "BrowDownLeft", "BrowDownRight", "BrowInnerUp", "BrowOuterUpLeft", "BrowOuterUpRight",
            "CheekPuff", "CheekSquintLeft", "CheekSquintRight",
            "NoseSneerLeft", "NoseSneerRight", "TongueOut"
        ];
        
        // Ratios from utils.py / Constants.swift
        public const float FacePositionXRatio = 100;
        public const float FacePositionYRatio = 100;
        public const float FacePositionZRatio = 50;
        public const float FaceAngleXRatio = 1;
        public const float FaceAngleYRatio = 1;
        public const float FaceAngleZRatio = 1;
        
        public const float MouthSmileRatio = 2;
        public const float MouseOpenRatio = 1.2f;
        public const float BrowsRatio = 2;
        public const float TongueOutRatio = 0.4f;
        
        public const float EyeOpenRatio = 1.25f;
        public const float EyeRotationRatio = 1.5f;
        
        public const float CheekPuffRatio = 2;
        public const float FaceAngryRatio = 0.3f;
        
        public const float BrowLeftYRatio = 2;
        public const float BrowRightYRatio = 2;
        public const float MouthXRatio = 2;
    }
}
