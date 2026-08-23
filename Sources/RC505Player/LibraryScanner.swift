import Foundation

/// Scans an RC-505 export folder (a flat directory of `<song>_<track>` subfolders,
/// e.g. "001_1", "001_2", "002_1") and groups the audio inside into songs.
enum LibraryScanner {
    private static let audioExtensions: Set<String> = ["wav", "aif", "aiff", "mp3"]

    private static let folderNamePattern = try! NSRegularExpression(pattern: "^(\\d+)_(\\d+)$")

    static func scan(rootURL: URL) -> [Song] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var songsByNumber: [Int: (label: String, tracks: [Track])] = [:]

        for entry in entries {
            guard (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true else { continue }

            let name = entry.lastPathComponent
            let fullRange = NSRange(name.startIndex..<name.endIndex, in: name)
            guard let match = folderNamePattern.firstMatch(in: name, range: fullRange),
                  let songRange = Range(match.range(at: 1), in: name),
                  let trackRange = Range(match.range(at: 2), in: name) else {
                continue
            }

            let songLabel = String(name[songRange])
            let trackLabel = String(name[trackRange])
            guard let songNumber = Int(songLabel), let trackNumber = Int(trackLabel) else { continue }
            guard let audioURL = firstAudioFile(in: entry) else { continue }

            let track = Track(key: name, number: trackNumber, defaultName: "Track \(trackNumber)", audioURL: audioURL)

            var value = songsByNumber[songNumber] ?? (label: songLabel, tracks: [])
            value.tracks.append(track)
            songsByNumber[songNumber] = value
        }

        return songsByNumber
            .map { number, value in
                Song(key: value.label, number: number, label: value.label, tracks: value.tracks.sorted { $0.number < $1.number })
            }
            .sorted { $0.number < $1.number }
    }

    private static func firstAudioFile(in folder: URL) -> URL? {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            return nil
        }
        return files
            .filter { audioExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .first
    }
}
