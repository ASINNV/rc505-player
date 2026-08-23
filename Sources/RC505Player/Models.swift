import Foundation

struct Track: Identifiable, Hashable {
    let id = UUID()
    /// Stable across re-scans of the same library — the track's folder name
    /// (e.g. "001_2") — used as the persisted-rename lookup key.
    let key: String
    let number: Int
    let defaultName: String
    let audioURL: URL

    func displayName(using store: NamesStore) -> String {
        store.name(for: key) ?? defaultName
    }
}

struct Song: Identifiable, Hashable {
    let id = UUID()
    /// Stable across re-scans of the same library — the song number label
    /// (e.g. "001") — used as the persisted-rename lookup key.
    let key: String
    let number: Int
    let label: String
    var tracks: [Track]

    var defaultDisplayName: String { "Song \(label)" }

    func displayName(using store: NamesStore) -> String {
        store.name(for: key) ?? defaultDisplayName
    }
}
