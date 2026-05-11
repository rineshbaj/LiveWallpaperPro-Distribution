// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiveWallpaperPro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LiveWallpaperPro", targets: ["LiveWallpaperPro"])
    ],
    targets: [
        .executableTarget(
            name: "LiveWallpaperPro",
            path: ".",
            sources: [
                "VideoWallpaperApp.swift",
                "ContentView.swift",
                "WallpaperView.swift",
                "WallpaperWindow.swift",
                "LibraryManager.swift",
                "LibraryView.swift"
            ]
        )
    ]
)
