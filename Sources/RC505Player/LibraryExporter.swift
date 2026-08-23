import Foundation

/// Copies every track of a song into a single flat destination folder, named
/// after the song, so tracks can be grabbed without digging through the
/// original per-track export folders.
enum LibraryExporter {
    enum ExportError: LocalizedError {
        case noTracks

        var errorDescription: String? {
            switch self {
            case .noTracks: return "This song has no tracks to export."
            }
        }
    }

    @MainActor
    static func export(song: Song, namesStore: NamesStore, to destinationParent: URL) throws -> URL {
        guard !song.tracks.isEmpty else { throw ExportError.noTracks }

        let fm = FileManager.default
        let folderURL = uniqueURL(for: sanitize(song.displayName(using: namesStore)), in: destinationParent)
        try fm.createDirectory(at: folderURL, withIntermediateDirectories: true)

        var usedNames = Set<String>()
        for track in song.tracks {
            let baseName = sanitize(track.displayName(using: namesStore))
            let ext = track.audioURL.pathExtension
            var fileName = ext.isEmpty ? baseName : "\(baseName).\(ext)"
            var suffix = 2
            while usedNames.contains(fileName) {
                fileName = ext.isEmpty ? "\(baseName) \(suffix)" : "\(baseName) \(suffix).\(ext)"
                suffix += 1
            }
            usedNames.insert(fileName)
            try fm.copyItem(at: track.audioURL, to: folderURL.appendingPathComponent(fileName))
        }

        return folderURL
    }

    private static func sanitize(_ name: String) -> String {
        let cleaned = name.components(separatedBy: CharacterSet(charactersIn: "/:")).joined(separator: "-")
        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    private static func uniqueURL(for name: String, in parent: URL) -> URL {
        let fm = FileManager.default
        var candidate = parent.appendingPathComponent(name, isDirectory: true)
        var suffix = 2
        while fm.fileExists(atPath: candidate.path) {
            candidate = parent.appendingPathComponent("\(name) \(suffix)", isDirectory: true)
            suffix += 1
        }
        return candidate
    }
}
