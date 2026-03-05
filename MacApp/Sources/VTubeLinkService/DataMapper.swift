import Foundation
import VTubeLinkShared

struct VTStudioParam: Encodable {
    let id: String
    let value: Float
}

class DataMapper {
    static func buildParamsDict(from data: CapturedData) -> [VTStudioParam] {
        var params: [VTStudioParam] = []
        
        let blendshapes = data.blendshapes
        
        func bs(_ key: String) -> Float {
            return blendshapes[key] ?? 0.0
        }
        
        // VTubeStudio Default
        params.append(VTStudioParam(id: "FacePositionX", value: data.headPositionX * Constants.facePositionXRatio))
        params.append(VTStudioParam(id: "FacePositionY", value: data.headPositionY * Constants.facePositionYRatio))
        params.append(VTStudioParam(id: "FacePositionZ", value: -data.headPositionZ * Constants.facePositionZRatio))
        
        params.append(VTStudioParam(id: "FaceAngleX", value: data.headRotationY * Constants.faceAngleXRatio))
        params.append(VTStudioParam(id: "FaceAngleY", value: -data.headRotationX * Constants.faceAngleYRatio))
        params.append(VTStudioParam(id: "FaceAngleZ", value: -data.headRotationZ * Constants.faceAngleZRatio))
        
        let mouthSmileLeft = bs("mouthSmile_L")
        let mouthSmileRight = bs("mouthSmile_R")
        let mouthShrugLower = bs("mouthShrugLower")
        let browDownLeft = bs("browDown_L")
        let browDownRight = bs("browDown_R")
        let jawOpen = bs("jawOpen")
        let mouthClose = bs("mouthClose")
        
        let smileInner1 = max(mouthSmileLeft + mouthSmileRight - 0.2, 0.0)
        let smileInner2 = pow(max(mouthShrugLower - 0.4, 0.0), 1.0) * 1.0
        let browDownAvg = (browDownLeft + browDownRight) / 2.0
        let mouthOpenFactor = (jawOpen - mouthClose) * 0.15
        let smileInner3 = pow(max(browDownAvg - 0.3 + (0.08 + mouthOpenFactor), 0.0), 0.4) * 1.5
        
        let mouthSmileVal = ((smileInner1 - smileInner2 - smileInner3) * Constants.mouthSmileRatio) / 2.0 + 0.5
        params.append(VTStudioParam(id: "MouthSmile", value: mouthSmileVal))
        
        params.append(VTStudioParam(id: "MouthOpen", value: (jawOpen - mouthClose) * Constants.mouseOpenRatio))
        params.append(VTStudioParam(id: "Brows", value: bs("browInnerUp") * Constants.browsRatio))
        
        let tongueOut = bs("tongueOut")
        params.append(VTStudioParam(id: "TongueOut", value: tongueOut < Constants.tongueOutRatio ? 0.0 : 1.0))
        
        let eyeOpenLeft = (1.0 - bs("eyeBlink_L")) * Constants.eyeOpenRatio - (Constants.eyeOpenRatio - 1.0)
        params.append(VTStudioParam(id: "EyeOpenLeft", value: eyeOpenLeft))
        
        let eyeOpenRight = (1.0 - bs("eyeBlink_R")) * Constants.eyeOpenRatio - (Constants.eyeOpenRatio - 1.0)
        params.append(VTStudioParam(id: "EyeOpenRight", value: eyeOpenRight))
        
        params.append(VTStudioParam(id: "EyeLeftX", value: (bs("eyeLookIn_L") - bs("eyeLookOut_L")) * Constants.eyeRotationRatio))
        params.append(VTStudioParam(id: "EyeLeftY", value: (bs("eyeLookUp_L") - bs("eyeLookDown_L")) * Constants.eyeRotationRatio))
        params.append(VTStudioParam(id: "EyeRightX", value: (bs("eyeLookOut_R") - bs("eyeLookIn_R")) * Constants.eyeRotationRatio))
        params.append(VTStudioParam(id: "EyeRightY", value: (bs("eyeLookUp_R") - bs("eyeLookDown_R")) * Constants.eyeRotationRatio))
        
        params.append(VTStudioParam(id: "CheekPuff", value: bs("cheekPuff") * Constants.cheekPuffRatio))
        
        let mouthRollLower = bs("mouthRollLower")
        params.append(VTStudioParam(id: "FaceAngry", value: (mouthRollLower * mouthShrugLower) < Constants.faceAngryRatio ? 0.0 : 1.0))
        
        let browOuterUpLeft = bs("browOuterUp_L")
        params.append(VTStudioParam(id: "BrowLeftY", value: ((browOuterUpLeft - browDownLeft) * Constants.browRightYRatio + 1.0) / 2.0))
        
        let browOuterUpRight = bs("browOuterUp_R")
        params.append(VTStudioParam(id: "BrowRightY", value: ((browOuterUpRight - browDownRight) * Constants.browRightYRatio + 1.0) / 2.0))
        
        params.append(VTStudioParam(id: "MouthX", value: (bs("mouthLeft") - bs("mouthRight")) * Constants.mouthXRatio))
        
        // Custom Params (ARKit) mapped from blendshapes 1-1 to customParams names
        let nameMappings: [String: String] = [
            "EyeBlinkLeft": "eyeBlink_L", "EyeLookDownLeft": "eyeLookDown_L", "EyeLookInLeft": "eyeLookIn_L",
            "EyeLookOutLeft": "eyeLookOut_L", "EyeLookUpLeft": "eyeLookUp_L", "EyeSquintLeft": "eyeSquint_L",
            "EyeWideLeft": "eyeWide_L", "EyeBlinkRight": "eyeBlink_R", "EyeLookDownRight": "eyeLookDown_R",
            "EyeLookInRight": "eyeLookIn_R", "EyeLookOutRight": "eyeLookOut_R", "EyeLookUpRight": "eyeLookUp_R",
            "EyeSquintRight": "eyeSquint_R", "EyeWideRight": "eyeWide_R", "JawForward": "jawForward",
            "JawLeft": "jawLeft", "JawRight": "jawRight", "JawOpen": "jawOpen", "MouthClose": "mouthClose",
            "MouthFunnel": "mouthFunnel", "MouthPucker": "mouthPucker", "MouthLeft": "mouthLeft", "MouthRight": "mouthRight",
            "MouthSmileLeft": "mouthSmile_L", "MouthSmileRight": "mouthSmile_R", "MouthFrownLeft": "mouthFrown_L",
            "MouthFrownRight": "mouthFrown_R", "MouthDimpleLeft": "mouthDimple_L", "MouthDimpleRight": "mouthDimple_R",
            "MouthStretchLeft": "mouthStretch_L", "MouthStretchRight": "mouthStretch_R", "MouthRollLower": "mouthRollLower",
            "MouthRollUpper": "mouthRollUpper", "MouthShrugLower": "mouthShrugLower", "MouthShrugUpper": "mouthShrugUpper",
            "MouthPressLeft": "mouthPress_L", "MouthPressRight": "mouthPress_R", "MouthLowerDownLeft": "mouthLowerDown_L",
            "MouthLowerDownRight": "mouthLowerDown_R", "MouthUpperUpLeft": "mouthUpperUp_L", "MouthUpperUpRight": "mouthUpperUp_R",
            "BrowDownLeft": "browDown_L", "BrowDownRight": "browDown_R", "BrowInnerUp": "browInnerUp",
            "BrowOuterUpLeft": "browOuterUp_L", "BrowOuterUpRight": "browOuterUp_R", "CheekPuff": "cheekPuff",
            "CheekSquintLeft": "cheekSquint_L", "CheekSquintRight": "cheekSquint_R", "NoseSneerLeft": "noseSneer_L",
            "NoseSneerRight": "noseSneer_R", "TongueOut": "tongueOut"
        ]
        
        for customParam in Constants.customParams {
            if let mappedKey = nameMappings[customParam] {
                params.append(VTStudioParam(id: customParam, value: bs(mappedKey)))
            } else {
                params.append(VTStudioParam(id: customParam, value: 0.0))
            }
        }
        
        return params
    }
}
