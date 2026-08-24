import SwiftUI
import AppKit

struct SongDetailView: View {
    let song: Song
    @ObservedObject var playback: PlaybackController
    @ObservedObject var namesStore: NamesStore
    @ObservedObject var organizer: SongOrganizerStore

    @State private var isRenamingSong = false
    @State private var renameText = ""
    @State private var exportError: String?

    private var isPlayingThisSong: Bool { playback.playingSongID == song.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(song.displayName(using: namesStore))
                    .font(.largeTitle)
                    .bold()

                Button {
                    organizer.toggleFavorite(song)
                } label: {
                    Image(systemName: organizer.isFavorite(song) ? "star.fill" : "star")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(organizer.isFavorite(song) ? .favoriteGold : .secondary)
                .help(organizer.isFavorite(song) ? "Remove from Favorites" : "Add to Favorites")

                Button {
                    renameText = song.displayName(using: namesStore)
                    isRenamingSong = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Rename this song")

                Spacer()

                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.secondary)
                Slider(value: $playback.masterVolume, in: 0...1)
                    .frame(width: 110)
                    .help("Master volume")

                Button {
                    exportSong()
                } label: {
                    Label("Export…", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .help("Copy all of this song's tracks into one folder")

                Button {
                    if isPlayingThisSong {
                        playback.stop()
                    } else {
                        playback.play(song: song)
                    }
                } label: {
                    Label(isPlayingThisSong ? "Stop" : "Play", systemImage: isPlayingThisSong ? "stop.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.space, modifiers: [])
            }
            .alert("Rename Song", isPresented: $isRenamingSong) {
                TextField("Name", text: $renameText)
                Button("Save") { namesStore.setName(renameText, for: song.key) }
                Button("Cancel", role: .cancel) {}
            }

            Text("\(song.tracks.count) track\(song.tracks.count == 1 ? "" : "s") · loops continuously until stopped")
                .foregroundStyle(.secondary)

            Divider()

            List {
                ForEach(song.tracks) { track in
                    TrackRow(track: track, playback: playback, namesStore: namesStore)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                }

                HStack {
                    Spacer()
                    Button {
                        playback.unmuteAll(song.tracks)
                    } label: {
                        Text("Unmute All")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!song.tracks.contains { playback.isMuted($0) })
                    .help("Unmute every track in this song")
                }
                .listRowInsets(EdgeInsets(top: 14, leading: 0, bottom: 6, trailing: 0))
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .padding()
        .id(song.id)
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private func exportSong() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.message = "Choose a location to export \"\(song.displayName(using: namesStore))\" into"

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        do {
            let folder = try LibraryExporter.export(song: song, namesStore: namesStore, to: destination)
            NSWorkspace.shared.activateFileViewerSelecting([folder])
        } catch {
            exportError = error.localizedDescription
        }
    }
}
