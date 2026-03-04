import Foundation

struct Constants {
    static let blendshapeNames = [
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
    ]
    
    static let customParams = [
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
    ]
    
    // Ratios from utils.py
    static let facePositionXRatio: Float = 100
    static let facePositionYRatio: Float = 100
    static let facePositionZRatio: Float = 50
    static let faceAngleXRatio: Float = 1
    static let faceAngleYRatio: Float = 1
    static let faceAngleZRatio: Float = 1
    
    static let mouthSmileRatio: Float = 2
    static let mouseOpenRatio: Float = 1.2
    static let browsRatio: Float = 2
    static let tongueOutRatio: Float = 0.4
    
    static let eyeOpenRatio: Float = 1.25
    static let eyeRotationRatio: Float = 1.5
    
    static let cheekPuffRatio: Float = 2
    static let faceAngryRatio: Float = 0.3
    
    static let browLeftYRatio: Float = 2
    static let browRightYRatio: Float = 2
    static let mouthXRatio: Float = 2
}
