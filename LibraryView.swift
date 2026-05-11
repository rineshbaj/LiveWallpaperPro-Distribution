import SwiftUI
import AVFoundation

// MARK: - Video Thumbnail Loader View
struct VideoThumbnailView: View {
    let item: WallpaperItem
    @EnvironmentObject var library: LibraryManager
    @State private var image: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let img = image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Placeholder
                ZStack {
                    Color(white: 0.15)
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .controlSize(.small)
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        library.generateThumbnail(for: item) { result in
            self.image = result
            self.isLoading = false
        }
    }
}

// MARK: - Library View
struct LibraryView: View {
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var manager: WallpaperManager
    @EnvironmentObject var license: LicenseManager
    
    let columns = [
        GridItem(.adaptive(minimum: 320, maximum: 500), spacing: 50)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text("Collection")
                    .font(.system(size: 32, weight: .light, design: .default))
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.top, 50)
                
                LazyVGrid(columns: columns, spacing: 50) {
                    ForEach(library.wallpapers) { item in
                        WallpaperCard(item: item)
                    }
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 60)
            }
        }
        .alert("Pro Feature", isPresented: $library.showProAlert) {
            Button("Get Pro License") {
                if let url = URL(string: "https://yourdomain.com#pricing") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This premium wallpaper requires a Pro license. Upgrade to unlock the entire collection.")
        }
    }
}

// MARK: - Wallpaper Card (Monolithic Cinema)
struct WallpaperCard: View {
    let item: WallpaperItem
    @EnvironmentObject var library: LibraryManager
    @EnvironmentObject var manager: WallpaperManager
    @EnvironmentObject var license: LicenseManager
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 1. Cinematic Image Frame
            ZStack {
                VideoThumbnailView(item: item)
                    .scaleEffect(isHovering ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.8), value: isHovering)
            }
            .frame(height: 220)
            .clipped()
            .cornerRadius(8) // Very subtle rounding, or 0 for pure sharp edges
            
            // 2. Minimalist Typography
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(white: 0.95))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(item.category.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color(white: 0.5))
                            .tracking(1.5)
                        
                        if item.isPremium && !license.isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(white: 0.8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(white: 0.2))
                                .cornerRadius(3)
                        }
                    }
                }
                
                Spacer()
                
                // 3. Invisible Action Button
                Button(action: {
                    handleAction()
                }) {
                    ZStack {
                        Circle()
                            .fill(isHovering ? Color(white: 0.2) : Color.clear)
                            .frame(width: 32, height: 32)
                            .animation(.easeOut(duration: 0.2), value: isHovering)
                        
                        if library.downloadingItems.contains(item.id) {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else if item.localVideoURL != nil {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.8))
                        } else {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(white: 0.8))
                                .opacity(isHovering ? 1.0 : 0.4)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onTapGesture {
            handleAction()
        }
    }
    
    func handleAction() {
        if item.isPremium && !license.isPro {
            library.showProAlert = true
            return
        }
        
        if let localURL = item.localVideoURL {
            if !manager.urls.contains(localURL) {
                manager.addWallpapers(urls: [localURL])
            }
            if let index = manager.urls.firstIndex(of: localURL) {
                manager.currentIndex = index
                manager.isWallpaperActive = true
            }
        } else {
            library.download(item: item) { url in
                if let url = url {
                    manager.addWallpapers(urls: [url])
                }
            }
        }
    }
}

