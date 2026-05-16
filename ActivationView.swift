import SwiftUI

struct ActivationView: View {
    @EnvironmentObject var license: LicenseManager
    @State private var licenseKey: String = ""
    @State private var isShowingSuccess = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("Activate Pro")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Enter your license key from Gumroad to unlock 500+ premium wallpapers and lifetime updates.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("LICENSE KEY")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                
                TextField("XXXX-XXXX-XXXX-XXXX", text: $licenseKey)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 40)
            
            if let error = license.lastError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            
            Button(action: {
                license.activate(key: licenseKey)
            }) {
                HStack {
                    if license.isValidating {
                        ProgressView().controlSize(.small).padding(.trailing, 5)
                    }
                    Text(license.isValidating ? "Validating..." : "Activate Now")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .disabled(licenseKey.isEmpty || license.isValidating)
            
            Button("Where is my key?") {
                if let url = URL(string: "https://rineshba.gumroad.com/l/zwcysk") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: license.isPro) { newValue in
            if newValue {
                isShowingSuccess = true
            }
        }
    }
}
