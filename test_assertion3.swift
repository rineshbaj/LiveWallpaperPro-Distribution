import Foundation
import IOKit.pwr_mgt

var dict: Unmanaged<CFDictionary>?
let result = IOPMCopyAssertionsByProcess(&dict)
if result == kIOReturnSuccess, let assertions = dict?.takeRetainedValue() as? [NSNumber: Any] {
    let myPid = ProcessInfo.processInfo.processIdentifier
    for (pid, info) in assertions {
        if pid.int32Value == myPid { continue }
        if let processAssertions = info as? [[String: Any]] {
            for assertion in processAssertions {
                let type = assertion[kIOPMAssertionTypeKey as String] as? String ?? ""
                let level = assertion[kIOPMAssertionLevelKey as String] as? Int ?? 0
                if type == "NoDisplaySleepAssertion" || type == "PreventUserIdleDisplaySleep" {
                    print("PID: \(pid), Type: \(type), Level: \(level)")
                }
            }
        }
    }
}
