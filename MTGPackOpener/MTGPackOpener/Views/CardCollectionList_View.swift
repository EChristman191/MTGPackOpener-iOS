import SwiftUI

struct CardCollectionList_View: View {
    @State private var collection: [CollectedCard] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.CUSTOM_lightBlue.ignoresSafeArea()

                if collection.isEmpty {
                    // Empty state
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
                    // Custom list look using ScrollView + LazyVStack
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(CardCollection_Service.sorted(collection)) { item in
                                NavigationLink(destination: Card_View(card: item.card)) {
                                    CardListRow(
                                        name: item.cardName,
                                        count: item.count,
                                        thumbURL: item.preferredImageURLString
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
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

// MARK: - Row View
private struct CardListRow: View {
    let name: String
    let count: Int
    let thumbURL: String?

    // Layout
    private let rowHeight: CGFloat = 110
    private let corner: CGFloat = 22

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            CardThumb(urlString: thumbURL)
                .frame(width: 70, height: 96) // keeps close to MTG aspect
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )

            // Name + count
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.custom(Font.CUSTOM_MTG_font, size: 22))
                    .foregroundColor(Color.CUSTOM_tan)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text("×\(count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: rowHeight)
        .background(
            // Dark rounded tile with subtle gradient & shadow
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.CUSTOM_darkBlue.opacity(0.95),
                            Color.black.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Thumbnail helper
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

// MARK: - Convenience accessors on CollectedCard
private extension CollectedCard {
    var cardName: String {
        if let faces = card.faces, let first = faces.first { return first.name }
        return card.name
    }
    var preferredImageURLString: String? {
        if let faces = card.faces, let first = faces.first {
            if let u = first.image_uris?["normal"] ?? first.image_uris?["large"] ?? first.image_uris?["small"] {
                return u
            }
        }
        return card.image_uris?["normal"] ?? card.image_uris?["large"] ?? card.image_uris?["small"]
    }
}
