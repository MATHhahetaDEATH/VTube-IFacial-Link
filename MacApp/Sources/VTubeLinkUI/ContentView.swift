import SwiftUI
import VTubeLinkShared

struct ContentView: View {
    @AppStorage("savedIPAddress") private var ipAddress = ""
    
    @State private var enableUDP = false
    @State private var enableVTS = false
    
    // Timer to sync GUI state to IPC config and check service process
    let syncTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    @State private var serviceProcess: Process?
    @State private var isServiceRunning = false
    
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
                TextField("e.g. 192.168.1.5", text: Binding(
                    get: { self.ipAddress },
                    set: { newValue in
                        self.ipAddress = newValue
                        self.updateSharedConfig()
                    }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
            }
            
            HStack(spacing: 40) {
                // UDP Toggle — green when enabled, red when disabled
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(enableUDP ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Toggle("iFacialMocap (UDP)", isOn: Binding(
                            get: { self.enableUDP },
                            set: { newValue in
                                self.enableUDP = newValue
                                self.updateSharedConfig()
                                self.ensureServiceRunning()
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
                
                // VTS Toggle — green when enabled, red when disabled
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(enableVTS ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Toggle("VTube Studio", isOn: Binding(
                            get: { self.enableVTS },
                            set: { newValue in
                                self.enableVTS = newValue
                                self.updateSharedConfig()
                                self.ensureServiceRunning()
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
            }
            
            Divider()
            
            HStack {
                Circle()
                    .fill(isServiceRunning ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(isServiceRunning ? "Background Service Running" : "Background Service Stopped")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Force Stop Service") {
                stopService()
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            loadInitialState()
        }
        .onReceive(syncTimer) { _ in
            checkServiceStatus()
        }
    }
    
    private func loadInitialState() {
        let config = ConfigManager.shared.loadConfig()
        if ipAddress.isEmpty && !config.ipAddress.isEmpty {
            ipAddress = config.ipAddress
        } else if !ipAddress.isEmpty {
            var fixedConfig = config
            fixedConfig.ipAddress = ipAddress
            ConfigManager.shared.saveConfig(fixedConfig)
        }
        enableUDP = config.enableUDP
        enableVTS = config.enableVTS
        checkServiceStatus()
    }
    
    private func updateSharedConfig() {
        let newConfig = ServiceConfig(ipAddress: ipAddress, enableUDP: enableUDP, enableVTS: enableVTS)
        ConfigManager.shared.saveConfig(newConfig)
    }
    
    private func ensureServiceRunning() {
        checkServiceStatus()
        if !isServiceRunning && (enableUDP || enableVTS) {
            startService()
        }
    }
    
    private func startService() {
        guard !isServiceRunning else { return }
        
        guard let execURL = Bundle.main.executableURL else {
            print("Failed to find main executable URL")
            return
        }
        
        let serviceURL = execURL.deletingLastPathComponent().appendingPathComponent("VTubeLinkService")
        
        let process = Process()
        process.executableURL = serviceURL
        
        do {
            try process.run()
            self.serviceProcess = process
            self.isServiceRunning = true
            print("Successfully launched VTubeLinkService PID: \(process.processIdentifier)")
        } catch {
            print("Failed to launch service: \(error)")
        }
    }
    
    private func stopService() {
        if let process = serviceProcess, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        serviceProcess = nil
        isServiceRunning = false
        
        // Also kill any orphaned VTubeLinkService processes
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killTask.arguments = ["-f", "VTubeLinkService"]
        try? killTask.run()
        
        // Toggle off the switches so it doesn't restart
        enableUDP = false
        enableVTS = false
        updateSharedConfig()
    }
    
    private func checkServiceStatus() {
        if let process = serviceProcess, process.isRunning {
            isServiceRunning = true
            return
        }
        
        // Global check if our Process handle is gone or not running
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "VTubeLinkService"]
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                isServiceRunning = true
            } else {
                isServiceRunning = false
            }
        } catch {
            isServiceRunning = false
        }
    }
}
