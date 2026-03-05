import Foundation
import Network
import VTubeLinkShared

class IFacialMocapReceiver: ObservableObject {
    @Published var isReceiving = false
    @Published var latestData = CapturedData()
    
    private var listener: NWListener?
    private var connection: NWConnection?
    private let port: NWEndpoint.Port = 49983
    
    func start(ipAddress: String) {
        guard !ipAddress.isEmpty else { return }
        
        // 1. Send the init ping to the iPhone
        let host = NWEndpoint.Host(ipAddress)
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let initString = "iFacialMocap_sahuasouryya9218sauhuiayeta91555dy3719"
                let data = initString.data(using: .utf8)
                self.connection?.send(content: data, completion: .contentProcessed({ error in
                    if let error = error {
                        print("UDP send error: \(error)")
                    } else {
                        print("Sent initialization string to iFacialMocap")
                    }
                }))
            default:
                break
            }
        }
        connection?.start(queue: .global())
        
        // 2. Start listening on port 49983 for incoming data
        do {
            listener = try NWListener(using: .udp, on: port)
            listener?.stateUpdateHandler = { state in
                print("Listener state: \(state)")
            }
            listener?.newConnectionHandler = { newConnection in
                newConnection.start(queue: .global())
                self.receiveMessage(on: newConnection)
            }
            listener?.start(queue: .global())
            DispatchQueue.main.async {
                self.isReceiving = true
            }
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async {
            self.isReceiving = false
        }
    }
    
    private func receiveMessage(on connection: NWConnection) {
        connection.receiveMessage { data, context, isComplete, error in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self.processData(message)
                self.receiveMessage(on: connection) // Continue listening
            } else if let error = error {
                print("Receive error: \(error)")
            }
        }
    }
    
    private func processData(_ rawData: String) {
        var paramsDict: [String: [Float]] = [:]
        
        let paramStrs = rawData.trimmingCharacters(in: CharacterSet(charactersIn: "|")).components(separatedBy: "|")
        for paramStr in paramStrs {
            if paramStr.contains("#") {
                let parts = paramStr.components(separatedBy: "#")
                guard parts.count == 2 else { continue }
                let key = parts[0]
                let valStrs = parts[1].components(separatedBy: ",")
                let vals = valStrs.compactMap { Float($0) }
                paramsDict[key] = vals
            } else if paramStr.contains("-") {
                let parts = paramStr.components(separatedBy: "-")
                guard parts.count == 2 else { continue }
                let key = parts[0]
                if let val = Float(parts[1]) {
                    paramsDict[key] = [val / 100.0]
                }
            }
        }
        
        var newData = CapturedData()
        
        for blendshape in Constants.blendshapeNames {
            if let val = paramsDict[blendshape]?.first {
                newData.blendshapes[blendshape] = val
            } else {
                newData.blendshapes[blendshape] = 0.0
            }
        }
        
        if let headVals = paramsDict["=head"], headVals.count >= 6 {
            newData.headRotationX = headVals[0]
            newData.headRotationY = headVals[1]
            newData.headRotationZ = headVals[2]
            newData.headPositionX = headVals[3]
            newData.headPositionY = headVals[4]
            newData.headPositionZ = headVals[5]
        }
        
        if let rightEye = paramsDict["rightEye"], rightEye.count >= 3 {
            newData.rightEyeRotationX = rightEye[0]
            newData.rightEyeRotationY = rightEye[1]
            newData.rightEyeRotationZ = rightEye[2]
        }
        
        if let leftEye = paramsDict["leftEye"], leftEye.count >= 3 {
            newData.leftEyeRotationX = leftEye[0]
            newData.leftEyeRotationY = leftEye[1]
            newData.leftEyeRotationZ = leftEye[2]
        }
        
        DispatchQueue.main.async {
            self.latestData = newData
        }
    }
}
