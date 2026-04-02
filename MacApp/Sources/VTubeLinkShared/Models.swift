import Foundation

public struct CapturedData {
    public var blendshapes: [String: Float]
    public var headRotationX: Float
    public var headRotationY: Float
    public var headRotationZ: Float
    public var headPositionX: Float
    public var headPositionY: Float
    public var headPositionZ: Float
    public var leftEyeRotationX: Float
    public var leftEyeRotationY: Float
    public var leftEyeRotationZ: Float
    public var rightEyeRotationX: Float
    public var rightEyeRotationY: Float
    public var rightEyeRotationZ: Float
    
    public init() {
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

public struct MappingUpdate: Codable {
    public var arkitParams: [String: Float]
    public var vtsParams: [String: Float]
    
    public init(arkitParams: [String: Float], vtsParams: [String: Float]) {
        self.arkitParams = arkitParams
        self.vtsParams = vtsParams
    }
}
