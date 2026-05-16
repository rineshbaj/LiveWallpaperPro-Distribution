import Foundation
import AppKit

class TelemetryManager {
    static let shared = TelemetryManager()
    
    // Replace this with your actual n8n webhook URL once set up
    private let endpoint = "https://your-n8n-instance.com/webhook/wallpaper-applied"
    
    func trackActivation(wallpaperURL: URL) {
        guard let deviceID = getDeviceUUID() else { return }
        
        let wallpaperID = wallpaperURL.lastPathComponent
        let timestamp = Date().timeIntervalSince1970
        
        let payload: [String: Any] = [
            "wallpaper_id": wallpaperID,
            "device_id": deviceID,
            "timestamp": timestamp,
            "platform": "macOS",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ]
        
        sendPing(payload: payload)
    }
    
    private func sendPing(payload: [String: Any]) {
        guard let url = URL(string: endpoint) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Telemetry: Failed to serialize payload")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Telemetry Ping Failed: \(error.localizedDescription)")
            } else {
                print("✅ Telemetry: Activation tracked for \(payload["wallpaper_id"] ?? "unknown")")
            }
        }
        task.resume()
    }
    
    private func getDeviceUUID() -> String? {
        // Get the IOPlatformUUID (Hardware UUID)
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if platformExpert > 0 {
            if let uuid = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String {
                IOObjectRelease(platformExpert)
                return uuid
            }
            IOObjectRelease(platformExpert)
        }
        return nil
    }
}
