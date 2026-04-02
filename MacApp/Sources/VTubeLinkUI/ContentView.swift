import SwiftUI
import VTubeLinkShared

// MARK: - Models
struct LogLine: Identifiable, Equatable {
    let id = UUID()
    let tag: String
    let message: String
}

// MARK: - ServiceManager
class ServiceManager: ObservableObject {
    @Published var ipAddress = ""
    @Published var enableUDP = false
    @Published var enableVTS = false
    @Published var isServiceRunning = false
    @Published var logLines: [LogLine] = []
    @Published var showMonitor = false
    
    // Filtering
    @Published var enabledTags: Set<String> = [] // Default all off as requested
    let availableTags = ["Service", "UDP", "VTS"]
    
    private var serviceProcess: Process?
    
    init() {
        loadInitialState()
    }
    
    func loadInitialState() {
        let config = ConfigManager.shared.loadConfig()
        self.ipAddress = config.ipAddress
        self.enableUDP = config.enableUDP
        self.enableVTS = config.enableVTS
        checkServiceStatus()
    }
    
    func updateSharedConfig() {
        let newConfig = ServiceConfig(ipAddress: ipAddress, enableUDP: enableUDP, enableVTS: enableVTS)
        ConfigManager.shared.saveConfig(newConfig)
        ensureServiceRunning()
    }
    
    func ensureServiceRunning() {
        checkServiceStatus()
        if !isServiceRunning && (enableUDP || enableVTS) {
            startService()
        }
    }
    
    func startService() {
        guard !isServiceRunning else { return }
        
        guard let execURL = Bundle.main.executableURL else {
            print("Failed to find main executable URL")
            return
        }
        
        let serviceURL = execURL.deletingLastPathComponent().appendingPathComponent("VTubeLinkService")
        
        let process = Process()
        process.executableURL = serviceURL
        
        // Capture logs
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.parseAndAddLogs(str)
                }
            }
        }
        
        do {
            try process.run()
            self.serviceProcess = process
            self.isServiceRunning = true
        } catch {
            print("Failed to launch service: \(error)")
        }
    }
    
    private func parseAndAddLogs(_ text: String) {
        let newLines = text.components(separatedBy: .newlines)
        for line in newLines where !line.isEmpty {
            var foundTag = "Other"
            for tag in availableTags {
                if line.contains("[\(tag)]") {
                    foundTag = tag
                    break
                }
            }
            let logLine = LogLine(tag: foundTag, message: line)
            logLines.append(logLine)
        }
        
        // Limit log size
        if logLines.count > 500 {
            logLines.removeFirst(logLines.count - 500)
        }
    }
    
    func stopService() {
        if let process = serviceProcess, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        serviceProcess = nil
        isServiceRunning = false
        
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        killTask.arguments = ["-f", "VTubeLinkService"]
        try? killTask.run()
        
        enableUDP = false
        enableVTS = false
        updateSharedConfig()
    }
    
    func checkServiceStatus() {
        if let process = serviceProcess, process.isRunning {
            isServiceRunning = true
            return
        }
        
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

// MARK: - MonitorView
struct MonitorView: View {
    @State private var arkitParams: [String: Float] = [:]
    @State private var vtsParams: [String: Float] = [:]
    @ObservedObject var serviceManager: ServiceManager
    
    var filteredLogs: [LogLine] {
        serviceManager.logLines.filter { line in
            serviceManager.enabledTags.contains(line.tag)
        }
    }
    
    var body: some View {
        HSplitView {
            VStack {
                Text("Parameter Mapping")
                    .font(.headline)
                    .padding(.top)
                
                HStack(alignment: .top) {
                    parameterColumn(title: "ARKit (Raw)", params: arkitParams)
                    Divider()
                    parameterColumn(title: "VTube Studio", params: vtsParams)
                }
            }
            .frame(minWidth: 400)
            
            VStack {
                Text("Service Logs")
                    .font(.headline)
                    .padding(.top)
                
                // Filter controls
                HStack(spacing: 15) {
                    Text("Filters:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(serviceManager.availableTags, id: \.self) { tag in
                        Toggle(tag, isOn: Binding(
                            get: { serviceManager.enabledTags.contains(tag) },
                            set: { newValue in
                                if newValue {
                                    serviceManager.enabledTags.insert(tag)
                                } else {
                                    serviceManager.enabledTags.remove(tag)
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredLogs) { line in
                                Text(line.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(colorForTag(line.tag))
                            }
                        }
                        .padding(.horizontal)
                        .id("logEnd")
                    }
                    .background(Color.black.opacity(0.1))
                    .onChange(of: filteredLogs.count) { _ in
                        proxy.scrollTo("logEnd", anchor: .bottom)
                    }
                }
            }
            .frame(minWidth: 350)
        }
        .padding()
        .onAppear {
            setupNotificationObserver()
        }
    }
    
    private func colorForTag(_ tag: String) -> Color {
        switch tag {
        case "VTS": return .blue
        case "UDP": return .green
        case "Service": return .orange
        default: return .primary
        }
    }
    
    private func parameterColumn(title: String, params: [String: Float]) -> some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List {
                ForEach(params.keys.sorted(), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(key)
                                .font(.system(size: 10, design: .monospaced))
                            Spacer()
                            Text(String(format: "%.3f", params[key] ?? 0))
                                .font(.system(size: 10, design: .monospaced))
                        }
                        Slider(value: Binding(
                            get: { params[key] ?? 0 },
                            set: { _ in }
                        ), in: 0...1)
                        .disabled(true)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private func setupNotificationObserver() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("VTubeLinkMappingUpdate"),
            object: nil,
            queue: .main
        ) { notification in
            guard let jsonString = notification.userInfo?["data"] as? String,
                  let data = jsonString.data(using: .utf8),
                  let update = try? JSONDecoder().decode(MappingUpdate.self, from: data) else {
                return
            }
            self.arkitParams = update.arkitParams
            self.vtsParams = update.vtsParams
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var serviceManager = ServiceManager()
    let syncTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
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
                TextField("e.g. 192.168.1.5", text: $serviceManager.ipAddress, onEditingChanged: { _ in
                    serviceManager.updateSharedConfig()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
            }
            
            HStack(spacing: 40) {
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(serviceManager.enableUDP ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Toggle("iFacialMocap (UDP)", isOn: Binding(
                            get: { serviceManager.enableUDP },
                            set: { newValue in
                                serviceManager.enableUDP = newValue
                                serviceManager.updateSharedConfig()
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
                
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(serviceManager.enableVTS ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Toggle("VTube Studio", isOn: Binding(
                            get: { serviceManager.enableVTS },
                            set: { newValue in
                                serviceManager.enableVTS = newValue
                                serviceManager.updateSharedConfig()
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                    }
                }
            }
            
            Divider()
            
            HStack {
                Circle()
                    .fill(serviceManager.isServiceRunning ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(serviceManager.isServiceRunning ? "Background Service Running" : "Background Service Stopped")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Force Stop Service") {
                serviceManager.stopService()
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .font(.caption)
            
            Divider()
            
            Button("Show Mapping Monitor") {
                serviceManager.showMonitor = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $serviceManager.showMonitor) {
                MonitorView(serviceManager: serviceManager)
                    .frame(minWidth: 800, minHeight: 600)
            }
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .onReceive(syncTimer) { _ in
            serviceManager.checkServiceStatus()
        }
    }
}
