import Foundation
import SwiftUI

class LicenseManager: ObservableObject {
    @Published var isActivated: Bool = false
    private let licenseKeyKey = "LWPRO_License_Key"
    
    init() {
        // Check if already activated locally
        if let _ = UserDefaults.standard.string(forKey: licenseKeyKey) {
            self.isActivated = true
        }
    }
    
    func activate(key: String) {
        // In a real app, you would verify this against a server (Gumroad API)
        // For our MVP, we will accept any key that looks like a Gumroad key 
        // (Format: XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX)
        
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedKey.count >= 10 {
            UserDefaults.standard.set(trimmedKey, forKey: licenseKeyKey)
            DispatchQueue.main.async {
                self.isActivated = true
            }
        }
    }
    
    func deactivate() {
        UserDefaults.standard.removeObject(forKey: licenseKeyKey)
        self.isActivated = false
    }
}
