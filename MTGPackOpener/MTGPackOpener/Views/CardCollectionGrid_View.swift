import SwiftUI

struct CardCollectionGrid_View: View {
    @State private var collection: [CollectedCard] = []

    // Layout tuning
    private let columnsCount: Int = 2
    private let hPadding: CGFloat = 12
    private let vPadding: CGFloat = 12
    private let tileSpacing: CGFloat = 10
    private let tileCorner: CGFloat = 12
    private let imageCorner: CGFloat = 10
    private let imageAspect: CGFloat = 63.0 / 88.0  // MTG card aspect

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let totalSpacing = tileSpacing * CGFloat(columnsCount - 1)
                let contentWidth = geo.size.width - (hPadding * 2) - totalSpacing
                let tileWidth = floor(contentWidth / CGFloat(columnsCount))
                let imageHeight = tileWidth / imageAspect

                ZStack {
                    Color.CUSTOM_lightBlue.ignoresSafeArea()

                    if collection.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 56))
                                .foregroundColor(.white.opacity(0.6))
                            Text(CardCollection_Service.emptyTitle)
                                .font(.custom(Font.CUSTOM_MTG_font, size: 20))
                                .foregroundColor(Color.CUSTOM_tan)
                            Text(CardCollection_Service.emptySubtitle)
                                .font(.custom(Font.CUSTOM_MTG_font, size: 14))
                                .foregroundColor(Color.CUSTOM_tan.opacity(0.8))
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: tileSpacing), count: columnsCount),
                                spacing: tileSpacing
                            ) {
                                ForEach(CardCollection_Service.sorted(collection)) { item in
                                    NavigationLink(destination: Card_View(card: item.card)) {
                                        CardGridTileCompact(
                                            card: item.card,
                                            tileWidth: tileWidth,
                                            imageHeight: imageHeight,
                                            tileCorner: tileCorner,
                                            imageCorner: imageCorner
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, hPadding)
                            .padding(.vertical, vPadding)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("\(currentUsername())’s Cards")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 24))
                            .foregroundColor(Color.CUSTOM_tan)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.CUSTOM_lightBlue, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
        .onAppear(perform: reloadCollection)
        .onReceive(NotificationCenter.default.publisher(for: .profilesActiveChanged)) { _ in
            reloadCollection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cardsCollectionChanged)) { _ in
            reloadCollection()
        }
    }

    private func reloadCollection() {
        collection = CardCollection_Service.load()
    }
    
    private func currentUsername() -> String {
            let profiles = ProfilesService.loadAll()
            if let activeID = ProfilesService.activeID(),
               let active = profiles.first(where: { $0.id == activeID }) {
                return active.username
            }
            return "My"
        }
}

// MARK: - Compact Tile (no name under image)
private struct CardGridTileCompact: View {
    let card: Card
    let tileWidth: CGFloat
    let imageHeight: CGFloat
    let tileCorner: CGFloat
    let imageCorner: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            CardThumb(urlString: preferredImageURLString(from: card))
                .frame(width: tileWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: imageCorner))
                .overlay(
                    RoundedRectangle(cornerRadius: imageCorner)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
        }
        .frame(width: tileWidth)
        .padding(6)
        .background(Color.CUSTOM_darkBlue)
        .clipShape(RoundedRectangle(cornerRadius: tileCorner))
        .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
    }

    private func preferredImageURLString(from c: Card) -> String? {
        // Prefer DFC face if present
        if let faces = c.faces, let first = faces.first {
            if let u = first.image_uris?["normal"] ?? first.image_uris?["large"] ?? first.image_uris?["small"] {
                return u
            }
        }
        return c.image_uris?["normal"] ?? c.image_uris?["large"] ?? c.image_uris?["small"]
    }
}

// MARK: - Thumbnail helper (keeps aspect & loading states)
private struct CardThumb: View {
    let urlString: String?

    var body: some View {
        AsyncImage(url: URL(string: urlString ?? "")) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Color.gray.opacity(0.12)
                    ProgressView()
                }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Image("DefaultCard")
                    .resizable()
                    .scaledToFill()
            @unknown default:
                EmptyView()
            }
        }
        .background(Color.gray.opacity(0.08))
        .clipped()
    }
}
