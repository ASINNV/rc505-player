import Foundation
import Combine

/// Persists user-chosen song/track names in UserDefaults, keyed by the
/// song/track's stable folder-derived key so custom names survive re-scanning
/// the library (e.g. on relaunch or re-choosing the same export folder).
@MainActor
final class NamesStore: ObservableObject {
    @Published private var customNames: [String: String]

    private static let defaultsKey = "customNames"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            customNames = decoded
        } else {
            customNames = [:]
        }
    }

    func name(for key: String) -> String? {
        customNames[key]
    }

    func setName(_ name: String, for key: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            customNames.removeValue(forKey: key)
        } else {
            customNames[key] = trimmed
        }
        guard let data = try? JSONEncoder().encode(customNames) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    /// Clears every custom name. Used when switching to a different export
    /// folder, since song/track keys are just numbers (e.g. "001", "001_1")
    /// and a new batch's numbering can otherwise collide with an old
    /// batch's, making old names appear to "carry over" onto new songs.
    func clearAll() {
        customNames.removeAll()
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
    }
}
