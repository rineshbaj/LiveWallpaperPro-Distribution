import SwiftUI
import AVFoundation

class PlayerView: NSView {
    override func makeBackingLayer() -> CALayer {
        return AVPlayerLayer()
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
}

struct WallpaperView: View {
    @ObservedObject var manager: WallpaperManager
    var isScreensaver: Bool = false
    @State private var overlayOpacity: Double = 0.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if manager.urls.isEmpty {
                    Color.black
                } else {
                    SlideshowView(manager: manager)
                }
                
                if manager.showClock && isScreensaver {
                    ClockView(manager: manager)
                        .scaleEffect(manager.clockScale)
                        .position(
                            x: geo.size.width * manager.clockX,
                            y: geo.size.height * manager.clockY
                        )
                }
                
                // Dimming Overlay
                if isScreensaver {
                    Color.black.opacity(overlayOpacity)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                if isScreensaver {
                    // Start the fade animation after the user-specified delay
                    withAnimation(.easeInOut(duration: 10.0).delay(manager.fadeTimeSeconds)) {
                        overlayOpacity = 1.0
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ClockView: View {
    @ObservedObject var manager: WallpaperManager
    @State private var currentTime = Date()
    // OPTIMIZATION: Only publish when the app is in the foreground/visible
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Group {
            switch manager.clockStyle {
            case .modern:
                VStack(spacing: 0) {
                    Text(currentTime, style: .time)
                        .font(.system(size: 120, weight: .thin, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    Text(currentTime, format: .dateTime.weekday().month().day())
                        .font(.system(size: 24, weight: .light, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .textCase(.uppercase)
                        .tracking(4)
                }
                    
            case .classic:
                Text(currentTime, style: .time)
                    .font(.system(size: 140, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
                    
            case .minimal:
                HStack {
                    Text(currentTime, style: .time)
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                    Text("|")
                    Text(currentTime, format: .dateTime.weekday().month().day())
                        .font(.system(size: 20, weight: .light, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(40)
                .background(Color.black.opacity(0.2))
                .cornerRadius(20)

            case .futuristic:
                VStack(spacing: 15) {
                    Text(currentTime, format: .dateTime.weekday())
                        .font(.system(size: 100, weight: .bold, design: .monospaced))
                        .textCase(.uppercase)
                        .tracking(10)
                    
                    Text(currentTime, format: .dateTime.day().month().year())
                        .font(.system(size: 30, weight: .light))
                    
                    Text(currentTime, style: .time)
                        .font(.system(size: 30, weight: .medium))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 2))
                }
                .foregroundColor(.white)

            case .ios:
                VStack(spacing: -20) {
                    Text(currentTime, format: .dateTime.weekday().month().day())
                        .font(.system(size: 24, weight: .medium))
                    
                    Text(currentTime, style: .time)
                        .font(.system(size: 220, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 10)
            }
        }
        .onReceive(timer) { input in
            if !manager.isOccluded {
                currentTime = input
            }
        }
    }
}

struct SlideshowView: View {
    @ObservedObject var manager: WallpaperManager
    @State private var timer: Timer?
    @State private var id = UUID()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let currentURL = manager.currentURL {
                    Group {
                        if let thumb = manager.currentThumbnail {
                            Image(nsImage: thumb)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.black
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .clipped()
                    
                    if isVideo(url: currentURL) {
                        SeamlessVideoPlayerView(url: currentURL, manager: manager)
                            .id(id)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else {
                        if let image = NSImage(contentsOf: currentURL) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                .clipped()
                                .id(id)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 1.0), value: manager.currentIndex)
        .onAppear {
            startTimer()
        }
        .onChange(of: manager.currentIndex) { _ in
            id = UUID()
            startTimer()
        }
        .onChange(of: manager.selectedInterval) { _ in
            startTimer()
        }
        .onChange(of: manager.customIntervalString) { _ in
            startTimer()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        
        // OPTIMIZATION: Don't even start the timer if we are hidden
        guard !manager.isOccluded else { return }
        
        if let interval = manager.timerIntervalInSeconds {
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                if !manager.isOccluded {
                    manager.advance()
                }
            }
        }
    }
    
    func isVideo(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "m4v"].contains(ext)
    }
}

struct SeamlessVideoPlayerView: NSViewRepresentable {
    let url: URL
    @ObservedObject var manager: WallpaperManager
    
    func makeNSView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.wantsLayer = true
        
        // OPTIMIZATION: Configure layer for direct hardware decoding path
        view.layer?.contentsGravity = .resizeAspectFill
        view.layer?.drawsAsynchronously = true // Offload from main thread
        
        let player = AVQueuePlayer()
        player.isMuted = true
        
        // OPTIMIZATION: Reduce buffering to save RAM/CPU
        player.automaticallyWaitsToMinimizeStalling = false
        
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        
        // OPTIMIZATION: Use specialized layer properties for video performance
        view.playerLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // OPTIMIZATION: Disable non-essential processing
        playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed
        
        let looper = AVPlayerLooper(player: player, templateItem: playerItem)
        context.coordinator.looper = looper
        context.coordinator.player = player
        
        if manager.pauseOnBattery && manager.isOnBattery {
            player.pause()
        } else {
            player.play()
        }
        
        return view
    }
    
    func updateNSView(_ nsView: PlayerView, context: Context) {
        context.coordinator.manager = manager
        context.coordinator.url = url
        context.coordinator.checkVisibility(nsView)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator: NSObject {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
        var manager: WallpaperManager?
        var url: URL?
        private var isOccluded = false
        
        func checkVisibility(_ nsView: NSView) {
            guard let window = nsView.window, let player = player, let manager = manager, let videoURL = url else { return }
            
            let isVisible = window.occlusionState.contains(.visible)
            let batteryPaused = manager.pauseOnBattery && manager.isOnBattery
            let spaceInactive = !manager.isSpaceActive
            
            // SAFETY GATE: Only update if the value actually changed
            let isHidden = !isVisible
            if manager.isOccluded != isHidden {
                DispatchQueue.main.async {
                    manager.isOccluded = isHidden
                }
            }
            
            if !isVisible || batteryPaused || spaceInactive {
                if player.rate != 0 {
                    player.pause()
                    player.replaceCurrentItem(with: nil) 
                }
            } else {
                if player.currentItem == nil {
                    let asset = AVURLAsset(url: manager.currentURL ?? videoURL)
                    let item = AVPlayerItem(asset: asset)
                    item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed
                    player.replaceCurrentItem(with: item)
                }
                player.play()
            }
            
            if nsView.postsBoundsChangedNotifications == false {
                nsView.postsBoundsChangedNotifications = true
                NotificationCenter.default.addObserver(self, selector: #selector(occlusionChanged), name: NSWindow.didChangeOcclusionStateNotification, object: window)
            }
        }
        
        @objc func occlusionChanged(_ notification: Notification) {
            guard let window = notification.object as? NSWindow, let player = player, let manager = manager, let videoURL = url else { return }
            let isVisible = window.occlusionState.contains(.visible)
            let batteryPaused = manager.pauseOnBattery && manager.isOnBattery
            
            // SAFETY GATE: Only update if the value actually changed
            let isHidden = !isVisible
            if manager.isOccluded != isHidden {
                DispatchQueue.main.async {
                    manager.isOccluded = isHidden
                }
            }
            
            if isVisible && !batteryPaused && manager.isSpaceActive {
                if player.currentItem == nil {
                    let asset = AVURLAsset(url: manager.currentURL ?? videoURL)
                    let item = AVPlayerItem(asset: asset)
                    item.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithm.varispeed
                    player.replaceCurrentItem(with: item)
                }
                player.play()
            } else {
                player.pause()
                player.replaceCurrentItem(with: nil)
            }
        }
    }
}
