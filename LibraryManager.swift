import SwiftUI
import Combine
import AVFoundation

struct WallpaperItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let videoURL: URL
    let thumbnailURL: URL
    let isPremium: Bool
    
    var localVideoURL: URL? {
        let fileManager = FileManager.default
        let appDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Screen Savers/VideoWallpaperData/Library")
        let targetURL = appDir.appendingPathComponent("\(id.uuidString).mp4")
        return fileManager.fileExists(atPath: targetURL.path) ? targetURL : nil
    }
}

class LibraryManager: ObservableObject {
    @Published var wallpapers: [WallpaperItem] = []
    @Published var downloadingItems: Set<UUID> = []
    @Published var showProAlert: Bool = false
    
    // Cache for generated video thumbnails
    private let imageCache = NSCache<NSURL, NSImage>()
    
    init() {
        loadLibrary()
    }
    
    func loadLibrary() {
        // --- In a real app, this would fetch from a JSON API ---
        // For now, we'll provide a curated list of high-quality, battery-efficient wallpapers
        self.wallpapers = [
            WallpaperItem(
                id: UUID(uuidString: "BB9314B4-FC4C-47D2-B5C2-4304D0667A9A")!,
                name: "Anime Spider-man Jump",
                category: "Anime",
                videoURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/Anime_Spiderma%20jump.mp4?download=true")!,
                thumbnailURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/Anime_Spiderma%20jump.mp4?download=true")!, // Used as key for generator
                isPremium: false
            ),
            WallpaperItem(
                id: UUID(uuidString: "1771A1A0-FD89-44A9-8A50-36F73FF24657")!,
                name: "Cyberpunk City Ruins",
                category: "Cyberpunk",
                videoURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/Cyberpunk_cityruins.mp4?download=true")!,
                thumbnailURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/Cyberpunk_cityruins.mp4?download=true")!,
                isPremium: true
            ),
            WallpaperItem(
                id: UUID(uuidString: "D021A5FF-03A2-4C4B-9ABA-978AA1B33BFB")!,
                name: "Abstract Beyond Human",
                category: "Abstract",
                videoURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/abstract_Beyond%20Human.mp4?download=true")!,
                thumbnailURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/abstract_Beyond%20Human.mp4?download=true")!,
                isPremium: false
            ),
            WallpaperItem(
                id: UUID(uuidString: "8F8B85A0-7916-41EC-B183-E2D67E3C04A6")!,
                name: "City Spider-man Noir",
                category: "Comic",
                videoURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/city_spider-man%20noir.mp4?download=true")!,
                thumbnailURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/city_spider-man%20noir.mp4?download=true")!,
                isPremium: true
            ),
            WallpaperItem(
                id: UUID(uuidString: "20983725-9D15-4555-ABCB-C7614EEF0465")!,
                name: "Nature Cloud Reflect",
                category: "Nature",
                videoURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/nature_Cloud%20Reflect.mp4?download=true")!,
                thumbnailURL: URL(string: "https://huggingface.co/datasets/Rineshbuzz/wallpapers/resolve/main/nature_Cloud%20Reflect.mp4?download=true")!,
                isPremium: false
            )
        ]
    }
    
    // MARK: - Thumbnail Generation
    
    func generateThumbnail(for item: WallpaperItem, completion: @escaping (NSImage?) -> Void) {
        let nsURL = item.videoURL as NSURL
        
        // 1. Check cache
        if let cachedImage = imageCache.object(forKey: nsURL) {
            completion(cachedImage)
            return
        }
        
        // 2. Generate asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: item.videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            // Generate frame at 1 second mark to avoid black fade-ins
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                
                // Cache and return
                self.imageCache.setObject(nsImage, forKey: nsURL)
                
                DispatchQueue.main.async {
                    completion(nsImage)
                }
            } catch {
                print("Failed to generate thumbnail for \(item.name): \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Downloading
    
    func download(item: WallpaperItem, completion: @escaping (URL?) -> Void) {
        guard !downloadingItems.contains(item.id) else { return }
        
        let fileManager = FileManager.default
        let appDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Screen Savers/VideoWallpaperData/Library")
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        let targetURL = appDir.appendingPathComponent("\(item.id.uuidString).mp4")
        
        if fileManager.fileExists(atPath: targetURL.path) {
            completion(targetURL)
            return
        }
        
        downloadingItems.insert(item.id)
        
        URLSession.shared.downloadTask(with: item.videoURL) { localURL, response, error in
            DispatchQueue.main.async {
                self.downloadingItems.remove(item.id)
                if let localURL = localURL {
                    do {
                        try fileManager.moveItem(at: localURL, to: targetURL)
                        completion(targetURL)
                    } catch {
                        print("Download Error: \(error)")
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
}

