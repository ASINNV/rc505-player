import Foundation
import Combine

/// Persists sidebar song favoriting and custom ordering in UserDefaults,
/// keyed by each song's stable folder-derived key so both survive
/// re-scanning the library (relaunch, or re-choosing the same export
/// folder).
@MainActor
final class SongOrganizerStore: ObservableObject {
    @Published private var favoriteKeys: Set<String>
    @Published private var orderedKeys: [String]

    private static let favoritesDefaultsKey = "favoriteSongKeys"
    private static let orderDefaultsKey = "songOrderKeys"

    init() {
        favoriteKeys = Set(UserDefaults.standard.stringArray(forKey: Self.favoritesDefaultsKey) ?? [])
        orderedKeys = UserDefaults.standard.stringArray(forKey: Self.orderDefaultsKey) ?? []
    }

    func isFavorite(_ song: Song) -> Bool {
        favoriteKeys.contains(song.key)
    }

    func toggleFavorite(_ song: Song) {
        if favoriteKeys.contains(song.key) {
            favoriteKeys.remove(song.key)
        } else {
            favoriteKeys.insert(song.key)
        }
        UserDefaults.standard.set(Array(favoriteKeys), forKey: Self.favoritesDefaultsKey)
    }

    /// All songs, ordered by any saved custom order (song number as a
    /// fallback for songs never reordered). Used for the "All Songs" tab.
    func sorted(_ songs: [Song]) -> [Song] {
        songs.sorted(by: byOrder)
    }

    /// Only favorited songs, in the same relative order as `sorted(_:)`.
    /// Used for the "Favorites" tab.
    func favoritesOnly(_ songs: [Song]) -> [Song] {
        songs.filter { isFavorite($0) }.sorted(by: byOrder)
    }

    private func index(of song: Song) -> Int {
        orderedKeys.firstIndex(of: song.key) ?? Int.max
    }

    private func byOrder(_ a: Song, _ b: Song) -> Bool {
        let (ia, ib) = (index(of: a), index(of: b))
        return ia != ib ? ia < ib : a.number < b.number
    }

    /// Reorders `displayed` (the exact array currently shown — either the
    /// full "All Songs" list or the filtered "Favorites" list) per a
    /// List's onMove indices, then merges that new subsequence back into
    /// the master order: every song NOT in `displayed` (e.g. non-favorites,
    /// while reordering the Favorites tab) keeps its existing relative
    /// position, so reordering one tab never disturbs the other's order.
    func move(allSongs: [Song], displayed: [Song], from source: IndexSet, to destination: Int) {
        var displayedKeys = displayed.map { $0.key }
        displayedKeys.move(fromOffsets: source, toOffset: destination)
        let displayedSet = Set(displayedKeys)

        let fullOrder = sorted(allSongs).map { $0.key }

        var newOrder: [String] = []
        var insertedSubset = false
        for key in fullOrder {
            if displayedSet.contains(key) {
                if !insertedSubset {
                    newOrder.append(contentsOf: displayedKeys)
                    insertedSubset = true
                }
            } else {
                newOrder.append(key)
            }
        }
        if !insertedSubset {
            newOrder.append(contentsOf: displayedKeys)
        }

        orderedKeys = newOrder
        UserDefaults.standard.set(orderedKeys, forKey: Self.orderDefaultsKey)
    }
}
