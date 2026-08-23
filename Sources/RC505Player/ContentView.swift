import SwiftUI
import AppKit

private enum SidebarTab: String, CaseIterable, Hashable {
    case all = "All Songs"
    case favorites = "Favorites"
}

struct ContentView: View {
    @State private var songs: [Song] = []
    @State private var selectedSongID: Song.ID?
    @State private var sidebarTab: SidebarTab = .all
    @State private var exportAllError: String?
    @StateObject private var playback = PlaybackController()
    @StateObject private var namesStore = NamesStore()
    @StateObject private var organizer = SongOrganizerStore()

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
                    Picker("", selection: $sidebarTab) {
                        ForEach(SidebarTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    let displayedSongs = sidebarTab == .all ? organizer.sorted(songs) : organizer.favoritesOnly(songs)

                    if displayedSongs.isEmpty {
                        Spacer()
                        Text("No favorites yet. Hover a song and click its star to add it here.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    } else {
                        List(selection: $selectedSongID) {
                            ForEach(displayedSongs) { song in
                                SongRow(song: song, isPlaying: playback.playingSongID == song.id, namesStore: namesStore, organizer: organizer)
                                    .tag(song.id)
                            }
                            .onMove { indices, newOffset in
                                organizer.move(allSongs: songs, displayed: displayedSongs, from: indices, to: newOffset)
                            }
                        }
                        .listStyle(.sidebar)

                        if sidebarTab == .favorites {
                            Button {
                                exportAllFavorites(displayedSongs)
                            } label: {
                                Label("Export All", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .help("Copy every favorite song's tracks into its own folder")
                        }
                    }
                }
            }
            .frame(minWidth: 220)
        } detail: {
            if let song = songs.first(where: { $0.id == selectedSongID }) {
                SongDetailView(song: song, playback: playback, namesStore: namesStore, organizer: organizer)
            } else {
                Text("Select a song")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear(perform: restoreLastFolder)
        .alert("Export Failed", isPresented: Binding(
            get: { exportAllError != nil },
            set: { if !$0 { exportAllError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportAllError ?? "")
        }
    }

    private func exportAllFavorites(_ favorites: [Song]) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.message = "Choose a location to export your \(favorites.count) favorite song\(favorites.count == 1 ? "" : "s") into"

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let favoritesFolder: URL
        do {
            favoritesFolder = try LibraryExporter.makeGroupFolder(named: "Favorites", in: destination)
        } catch {
            exportAllError = error.localizedDescription
            return
        }

        var exportedAny = false
        var failures: [String] = []

        for song in favorites {
            do {
                _ = try LibraryExporter.export(song: song, namesStore: namesStore, to: favoritesFolder)
                exportedAny = true
            } catch {
                failures.append("\(song.displayName(using: namesStore)): \(error.localizedDescription)")
            }
        }

        if exportedAny {
            NSWorkspace.shared.activateFileViewerSelecting([favoritesFolder])
        }
        if !failures.isEmpty {
            exportAllError = failures.joined(separator: "\n")
        }
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
