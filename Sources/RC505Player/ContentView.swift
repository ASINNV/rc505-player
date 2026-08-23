import SwiftUI
import AppKit

struct ContentView: View {
    @State private var songs: [Song] = []
    @State private var selectedSongID: Song.ID?
    @StateObject private var playback = PlaybackController()

    private static let lastFolderKey = "lastLibraryPath"

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    chooseFolder()
                } label: {
                    Label("Choose Export Folder…", systemImage: "folder")
                }
                .padding()

                if songs.isEmpty {
                    Spacer()
                    Text("Choose the folder containing your RC-505 song/track exports (the one full of \"001_1\", \"001_2\"… subfolders) to get started.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    List(songs, selection: $selectedSongID) { song in
                        HStack {
                            Text(song.displayName)
                            Spacer()
                            if playback.playingSongID == song.id {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .tag(song.id)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 220)
        } detail: {
            if let song = songs.first(where: { $0.id == selectedSongID }) {
                SongDetailView(song: song, playback: playback)
            } else {
                Text("Select a song")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: restoreLastFolder)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            loadLibrary(from: url)
        }
    }

    private func loadLibrary(from url: URL) {
        playback.stop()
        songs = LibraryScanner.scan(rootURL: url)
        selectedSongID = songs.first?.id
        UserDefaults.standard.set(url.path, forKey: Self.lastFolderKey)
    }

    private func restoreLastFolder() {
        guard songs.isEmpty, let path = UserDefaults.standard.string(forKey: Self.lastFolderKey) else { return }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else { return }
        loadLibrary(from: URL(fileURLWithPath: path))
    }
}
