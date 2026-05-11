import Foundation
import IOKit.pwr_mgt

var assertionID: IOPMAssertionID = 0
let reasonForActivity = "Video Wallpaper Idle Mode" as CFString

let success = IOPMAssertionCreateWithName(
    kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
    IOPMAssertionLevel(kIOPMAssertionLevelOn),
    reasonForActivity,
    &assertionID
)

if success == kIOReturnSuccess {
    print("Assertion created successfully: \(assertionID)")
    IOPMAssertionRelease(assertionID)
} else {
    print("Failed to create assertion")
}
