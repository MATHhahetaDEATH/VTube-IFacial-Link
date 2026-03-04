import SwiftUI

struct ContentView: View {
    @StateObject private var receiver = IFacialMocapReceiver()
    @StateObject private var vtsManager = VTubeStudioManager()
    
    @State private var ipAddress = "192.168.0.1"
    
    // Timer to poll receiver latest_data and push to VTS
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect() // ~60 FPS
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "face.dashed")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
            
            Text("VTube-iFacialMocap-Link")
                .font(.headline)
            
            HStack {
                Text("IP Address:")
                TextField("e.g. 192.168.1.5", text: $ipAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
            }
            
            HStack(spacing: 40) {
                // Receiver Status
                VStack {
                    Circle()
                        .fill(receiver.isReceiving ? Color.green : Color.red)
                        .frame(width: 20, height: 20)
                    Text("UDP Stream")
                        .font(.caption)
                }
                
                // VTS Status
                VStack {
                    Circle()
                        .fill(vtsManager.isAuthenticated ? Color.green : Color.red)
                        .frame(width: 20, height: 20)
                    Text("VTube Studio")
                        .font(.caption)
                }
            }
            
            Button(action: toggleConnection) {
                Text(receiver.isReceiving ? "Disconnect" : "Connect")
                    .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .tint(receiver.isReceiving ? .red : .blue)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .onReceive(timer) { _ in
            if receiver.isReceiving && vtsManager.isAuthenticated {
                let params = DataMapper.buildParamsDict(from: receiver.latestData)
                vtsManager.sendParameters(params)
            }
        }
    }
    
    private func toggleConnection() {
        if receiver.isReceiving {
            receiver.stop()
            vtsManager.disconnect()
        } else {
            receiver.start(ipAddress: ipAddress)
            vtsManager.connect()
        }
    }
}
