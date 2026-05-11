import AppKit
import Foundation

class WallpaperWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configuration for background window
        self.isOpaque = true
        self.backgroundColor = .black
        self.hasShadow = false
        self.ignoresMouseEvents = true // Allow clicking icons on desktop
        
        // Place behind desktop icons
        // kCGDesktopIconWindowLevel is the level of the icons.
        // We want to be just below icons but above the actual desktop wallpaper image.
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        
        // Join all spaces and stay stationary
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // Ensure it fills the screen
        self.setFrame(screen.frame, display: true)
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}
