import Foundation

struct Track: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let name: String
    let audioURL: URL
}

struct Song: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let label: String
    var tracks: [Track]

    var displayName: String { "Song \(label)" }
}
