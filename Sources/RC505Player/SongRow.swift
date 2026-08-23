import SwiftUI

struct SongRow: View {
    let song: Song
    let isPlaying: Bool
    @ObservedObject var namesStore: NamesStore
    @ObservedObject var organizer: SongOrganizerStore
    let onRename: () -> Void

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
            .help(isFavorite ? "Remove from Favorites (CMD+F)" : "Add to Favorites (CMD+F)")
            .opacity((isFavorite || isRowHovering) ? 1 : 0)
            .allowsHitTesting(isFavorite || isRowHovering)

            HStack(spacing: 6) {
                Text(song.displayName(using: namesStore))

                Button(action: onRename) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Rename this song (CMD+R)")
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
            Button("Rename…", action: onRename)
            Button(isFavorite ? "Remove from Favorites (CMD+F)" : "Add to Favorites (CMD+F)") {
                organizer.toggleFavorite(song)
            }
        }
    }
}
