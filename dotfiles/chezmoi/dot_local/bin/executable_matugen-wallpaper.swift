#!/usr/bin/swift
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("matugen-wallpaper: \(message)\n".utf8))
    exit(1)
}

func plist(_ data: Data) throws -> [String: Any] {
    guard let value = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw NSError(domain: "Invalid property list", code: 1)
    }
    return value
}

let home = FileManager.default.homeDirectoryForCurrentUser
let wallpaperStore = home.appendingPathComponent("Library/Application Support/com.apple.wallpaper/Store/Index.plist")
let cache = home.appendingPathComponent("Library/Caches/matugen-wallpaper", isDirectory: true)

do {
    let store = try plist(Data(contentsOf: wallpaperStore))
    guard let all = store["AllSpacesAndDisplays"] as? [String: Any],
          let linked = all["Linked"] as? [String: Any],
          let content = linked["Content"] as? [String: Any],
          let choices = content["Choices"] as? [[String: Any]],
          let choice = choices.first,
          let configuration = choice["Configuration"] as? Data,
          let urlInfo = try plist(configuration)["url"] as? [String: Any],
          let relative = urlInfo["relative"] as? String,
          var wallpaper = URL(string: relative), wallpaper.isFileURL else {
        fail("cannot find a shared wallpaper in the macOS wallpaper store")
    }
    if wallpaper.pathExtension == "madesktop" {
        let descriptor = try plist(Data(contentsOf: wallpaper))
        guard let asset = descriptor["mobileAssetID"] as? String else { fail("wallpaper has no desktop asset") }
        wallpaper = home.appendingPathComponent("Library/Application Support/com.apple.mobileAssetDesktop/\(asset).heic")
    }
    let data = try Data(contentsOf: wallpaper, options: .mappedIfSafe)
    let dark = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleInterfaceStyle"] as? String == "Dark"
    var index = 0
    let marker = Data("apple_desktop:apr=\"".utf8)
    if let start = data.range(of: marker)?.upperBound,
       let end = data[start...].firstIndex(of: 34),
       let encoded = String(data: data[start..<end], encoding: .utf8),
       let metadata = Data(base64Encoded: encoded),
       let variants = try? plist(metadata),
       let variant = variants[dark ? "d" : "l"] as? Int {
        index = variant
    } else if let source = CGImageSourceCreateWithURL(wallpaper as CFURL, nil), CGImageSourceGetCount(source) > 1 {
        fail("this dynamic wallpaper does not provide light/dark image metadata")
    }
    let attributes = try FileManager.default.attributesOfItem(atPath: wallpaper.path)
    let modified = (attributes[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
    let config = home.appendingPathComponent(".config/matugen/config.toml")
    let template = home.appendingPathComponent(".config/matugen/templates/ghostty")
    let configDate = try FileManager.default.attributesOfItem(atPath: config.path)[.modificationDate] as? Date
    let templateDate = try FileManager.default.attributesOfItem(atPath: template.path)[.modificationDate] as? Date
    let key = "\(wallpaper.path)\n\(modified)\n\(index)\n\(dark)\n\(configDate?.timeIntervalSince1970 ?? 0)\n\(templateDate?.timeIntervalSince1970 ?? 0)"
    try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
    let state = cache.appendingPathComponent("state")
    let output = home.appendingPathComponent(".config/ghostty/themes/matugen")
    if (try? String(contentsOf: state, encoding: .utf8)) == key && FileManager.default.fileExists(atPath: output.path) { exit(0) }
    guard let source = CGImageSourceCreateWithURL(wallpaper as CFURL, nil),
          let image = CGImageSourceCreateThumbnailAtIndex(source, index, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: 512] as CFDictionary) else {
        fail("cannot decode wallpaper image \(index)")
    }
    let imagePath = cache.appendingPathComponent("wallpaper.png")
    guard let destination = CGImageDestinationCreateWithURL(imagePath as CFURL, UTType.png.identifier as CFString, 1, nil) else { fail("cannot create wallpaper image") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fail("cannot save wallpaper image") }
    let candidates = [home.appendingPathComponent(".cargo/bin/matugen").path, "/opt/homebrew/bin/matugen", "/usr/local/bin/matugen"]
    guard let executable = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else { fail("matugen is not installed") }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = ["-c", config.path, "-m", dark ? "dark" : "light", "-t", "scheme-expressive", "--source-color-index", "0", "image", imagePath.path]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { fail("matugen failed with status \(process.terminationStatus)") }
    try key.write(to: state, atomically: true, encoding: .utf8)
} catch {
    fail(error.localizedDescription)
}
