import SwiftUI

struct SongRow: View {
    let song: Song
    let isPlaying: Bool
    @ObservedObject var namesStore: NamesStore
    @ObservedObject var organizer: SongOrganizerStore

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isRowHovering = false
    @State private var isNameHovering = false

    private var isFavorite: Bool { organizer.isFavorite(song) }

    var body: some View {
        HStack {
            Button {
                organizer.toggleFavorite(song)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(isFavorite ? .white : .secondary)
            .help(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            .opacity((isFavorite || isRowHovering) ? 1 : 0)
            .allowsHitTesting(isFavorite || isRowHovering)

            HStack(spacing: 6) {
                Text(song.displayName(using: namesStore))

                Button {
                    renameText = song.displayName(using: namesStore)
                    isRenaming = true
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Rename this song")
                .opacity(isNameHovering ? 1 : 0)
                .allowsHitTesting(isNameHovering)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    withAnimation(.easeInOut(duration: 0.15)) { isNameHovering = true }
                } else {
                    isNameHovering = false
                }
            }

            Spacer()
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                withAnimation(.easeInOut(duration: 0.15)) { isRowHovering = true }
            } else {
                isRowHovering = false
            }
        }
        .contextMenu {
            Button("Rename…") {
                renameText = song.displayName(using: namesStore)
                isRenaming = true
            }
            Button(isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                organizer.toggleFavorite(song)
            }
        }
        .alert("Rename Song", isPresented: $isRenaming) {
            TextField("Name", text: $renameText)
            Button("Save") { namesStore.setName(renameText, for: song.key) }
            Button("Cancel", role: .cancel) {}
        }
    }
}
