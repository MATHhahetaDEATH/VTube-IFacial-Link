import Foundation
import VTubeLinkShared

@main
struct VTubeLinkService {
    static var receiver: IFacialMocapReceiver!
    static var vtsManager: VTubeStudioManager!
    static var lastConfig = ServiceConfig(ipAddress: "", enableUDP: false, enableVTS: false)
    
    static var timer: Timer?
    
    static func main() {
        print("VTubeLinkService Background Daemon Started.")
        
        receiver = IFacialMocapReceiver()
        vtsManager = VTubeStudioManager()
        // Wire up the data source so the VTS injection loop reads from the receiver
        vtsManager.dataSource = receiver
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkConfig()
        }
        
        RunLoop.main.run()
    }
    
    static func checkConfig() {
        let currentConfig = ConfigManager.shared.loadConfig()
        guard currentConfig != lastConfig else { return }
        print("Service detected config transition: \(lastConfig) -> \(currentConfig)")
        
        // Handle UDP modifications
        if currentConfig.enableUDP != lastConfig.enableUDP || (currentConfig.enableUDP && currentConfig.ipAddress != lastConfig.ipAddress) {
            receiver.stop()
            if currentConfig.enableUDP {
                print("Starting UDP receiver on \(currentConfig.ipAddress)")
                receiver.start(ipAddress: currentConfig.ipAddress)
            }
        }
        
        // Handle VTS modifications
        if currentConfig.enableVTS != lastConfig.enableVTS {
            if currentConfig.enableVTS {
                print("Starting VTube Studio connection")
                vtsManager.connect()
            } else {
                print("Stopping VTube Studio connection")
                vtsManager.disconnect()
            }
        }
        
        lastConfig = currentConfig
    }
}
