import Foundation

struct CapturedData {
    var blendshapes: [String: Float]
    var headRotationX: Float
    var headRotationY: Float
    var headRotationZ: Float
    var headPositionX: Float
    var headPositionY: Float
    var headPositionZ: Float
    var leftEyeRotationX: Float
    var leftEyeRotationY: Float
    var leftEyeRotationZ: Float
    var rightEyeRotationX: Float
    var rightEyeRotationY: Float
    var rightEyeRotationZ: Float
    
    init() {
        self.blendshapes = [:]
        self.headRotationX = 0
        self.headRotationY = 0
        self.headRotationZ = 0
        self.headPositionX = 0
        self.headPositionY = 0
        self.headPositionZ = 0
        self.leftEyeRotationX = 0
        self.leftEyeRotationY = 0
        self.leftEyeRotationZ = 0
        self.rightEyeRotationX = 0
        self.rightEyeRotationY = 0
        self.rightEyeRotationZ = 0
    }
}
