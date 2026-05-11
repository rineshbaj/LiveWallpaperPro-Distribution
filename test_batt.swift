import Foundation
import IOKit.ps

if let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
   let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [Any] {
    for item in list {
        if let source = item as? [String: Any] {
            if let state = source[kIOPSPowerSourceStateKey as String] as? String {
                print("State: \(state)")
            }
        }
    }
}
