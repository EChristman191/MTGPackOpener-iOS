import SwiftUI
import UIKit

struct Card_View: View {
    let card: Card

    // MARK: SFX
    private let flipSFXName = "card_flip_sfx"
    private let flipSFXExt  = "mp3"
    private let PAGE_NAV_TITLE = ""

    // MARK: Colors
    var DEFAULT_BORDER_COLOR = Color.CUSTOM_lightBlue
    var WAVE_RARITY_COLOR: Color {
        switch card.rarity.lowercased() {
        case "common": return .gray
        case "uncommon": return .green
        case "rare": return .blue
        case "mythic": return .purple
        case "legendary": return .orange
        default: return .gray
        }
    }

    // DFC state
    @State private var faceIndex: Int = 0
    @State private var showingImage: Bool = true

    // Delete sheet state
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteSheet = false
    @State private var showDeleteError = false
    @State private var selectedDeleteQty: Int = 1
    @State private var maxDeleteQty: Int = 1

    // MARK: Share state
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var shareFileURL: URL?   // named temp file so Photos/Files can save it with a name

    // Name to show (DFC-aware)
    private var visibleName: String {
        if let faces = card.faces, !faces.isEmpty, faceIndex < faces.count {
            return faces[faceIndex].name
        }
        return card.name
    }

    // Best image URL (DFC-aware)
    private func bestImageURL() -> URL? {
        if let faces = card.faces, !faces.isEmpty, faceIndex < faces.count,
           let u = pickURL(from: faces[faceIndex].image_uris) { return u }
        return pickURL(from: card.image_uris)
    }
    private func pickURL(from dict: [String: String]?) -> URL? {
        guard let dict = dict else { return nil }
        for key in ["normal","large","png","border_crop","art_crop","small"] {
            if let s = dict[key], let u = URL(string: s) { return u }
        }
        return nil
    }

    // MARK: Share helpers

    /// Use Scryfall exact-name search with quotes so the link always works.
    private var shareWebURL: URL? {
        let quoted = "\"\(visibleName)\""
        let q = quoted.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? quoted
        return URL(string: "https://scryfall.com/search?q=%21\(q)")
    }

    /// Download the actual card image bytes (so we share pixels, not a placeholder).
    private func fetchCardImageData() async -> Data? {
        guard let url = bestImageURL() else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { return nil }
            return data
        } catch {
            return nil
        }
    }

    /// Write a named temp PNG so destinations like Photos/Files save with a real filename.
    @MainActor
    private func writeTempImage(_ image: UIImage, name: String) -> URL? {
        let safe = name.replacingOccurrences(of: "[^A-Za-z0-9_-]+", with: "_", options: .regularExpression)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safe).png")
        guard let png = image.pngData() else { return nil }
        do {
            try png.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// MARK: Download and prep share image (UIImage + file URL). The sheet builds the single smart item.
    @MainActor
    private func renderShareImage() {
        Task {
            guard let data = await fetchCardImageData(),
                  let uiImage = UIImage(data: data) else {
                return
            }
            self.shareImage = uiImage
            self.shareFileURL = writeTempImage(uiImage, name: visibleName)
            self.showShareSheet = true
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(spacing: 4) {
                    Text(visibleName)
                        .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                        .foregroundColor(Color.CUSTOM_tan)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    Text(card.rarity)
                        .font(.subheadline)
                        .foregroundColor(WAVE_RARITY_COLOR)
                        .bold()
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                Divider().background(Color.CUSTOM_tan)

                // Image
                if let url = bestImageURL() {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                                ProgressView()
                            }
                            .aspectRatio(63.0/88.0, contentMode: .fit)
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .aspectRatio(63.0/88.0, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                                .opacity(showingImage ? 1 : 0)
                                .animation(.easeInOut(duration: 0.2), value: showingImage)
                        case .failure:
                            Image("DefaultCard")
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(63.0/88.0, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(radius: 4)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image("DefaultCard")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(63.0/88.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                }

                // Flip (DFC)
                if let faces = card.faces, faces.count > 1 {
                    HStack {
                        Spacer()
                        Button {
                            // play flip sound immediately
                            _ = SoundManager.shared.play(flipSFXName, ext: flipSFXExt, volume: 0.85)

                            // do the visual flip
                            withAnimation(.easeInOut(duration: 0.2)) { showingImage = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                faceIndex = (faceIndex + 1) % faces.count
                                withAnimation(.easeInOut(duration: 0.2)) { showingImage = true }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Flip").font(.custom(Font.CUSTOM_MTG_font, size: 16))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.CUSTOM_darkBlue)
                        .foregroundColor(Color.CUSTOM_tan)
                        .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.CUSTOM_darkBlue)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .waveStroke(
                        color1: WAVE_RARITY_COLOR,
                        color2: DEFAULT_BORDER_COLOR,
                        lineWidth: 8,
                        duration: 1.5
                    )
            )
            .padding()
        }
        .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
        .navigationTitle(PAGE_NAV_TITLE)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Existing delete button
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let count = CardCollection_Service.count(for: card)
                    if count > 0 {
                        maxDeleteQty = count
                        selectedDeleteQty = min(max(1, selectedDeleteQty), maxDeleteQty)
                        showDeleteSheet = true
                    } else {
                        showDeleteError = true
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .foregroundColor(.red)
                .accessibilityLabel("Delete copies…")
            }

            // MARK: Share menu
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let pageURL = shareWebURL {
                        // Minimal ShareLink so "Copy" copies the raw URL (no subject/message)
                        ShareLink(
                            item: pageURL,
                            preview: SharePreview(
                                Text(visibleName),
                                image: Image(systemName: "link")
                            )
                        ) {
                            Label("Share Link", systemImage: "link")
                        }

                        // Explicit Copy Link (always copies the URL string)
                        Button {
                            UIPasteboard.general.string = pageURL.absoluteString
                        } label: {
                            Label("Copy Link", systemImage: "doc.on.doc")
                        }
                    }

                    Button {
                        renderShareImage()  // downloads & preps a single smart share item
                    } label: {
                        Label("Share Image…", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        // Delete qty sheet — CUSTOM_lightBlue background
        .sheet(isPresented: $showDeleteSheet) {
            // Full-bleed CUSTOM_lightBlue background behind the sheet content
            ZStack {
                Color.CUSTOM_lightBlue.ignoresSafeArea()  // background layer

                DeleteQuantitySheet(
                    name: visibleName,
                    maxQty: maxDeleteQty,
                    selectedQty: $selectedDeleteQty,
                    onCancel: { showDeleteSheet = false },
                    onConfirm: {
                        let removed = CardCollection_Service.delete(matching: card, quantity: selectedDeleteQty)
                        showDeleteSheet = false
                        if removed > 0 {
                            if CardCollection_Service.count(for: card) == 0 { dismiss() }
                        } else {
                            showDeleteError = true
                        }
                    }
                )
                .onAppear {
                    let live = CardCollection_Service.count(for: card)
                    maxDeleteQty = max(1, live)
                    selectedDeleteQty = min(max(1, selectedDeleteQty), maxDeleteQty)
                }
            }
            .presentationDetents([.height(260)])          // keep your detent
            .presentationDragIndicator(.visible)
            // iOS 17+ consistent sheet chrome background
            .modifier(LightBlueSheetBackground())
        }
        // Share sheet: build ONE smart item to avoid duplicate images
        .sheet(isPresented: $showShareSheet) {
            ZStack {
                Color.CUSTOM_lightBlue.ignoresSafeArea()  // background layer for share sheet too

                if let img = shareImage {
                    let item = CardImageItemSource(image: img, fileURL: shareFileURL, title: visibleName)
                    ActivityView(activityItems: [item])
                        .ignoresSafeArea()
                } else {
                    Color.clear.onAppear { showShareSheet = false }
                }
            }
            // iOS 17+ consistent sheet chrome background
            .modifier(LightBlueSheetBackground())
            Color.CUSTOM_lightBlue.ignoresSafeArea()
                .onAppear { showShareSheet = false }
        }
        .alert("Couldn’t delete", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We couldn’t find copies of this card in your collection.")
        }
        .onAppear {
            // Preload the flip sound (so it’s instant on first tap)
            SoundManager.shared.preload([(flipSFXName, flipSFXExt)])

            showingImage = true
            faceIndex = 0
        }
    }
}

// MARK: - Helper to apply iOS 17+ sheet background consistently
private struct LightBlueSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.presentationBackground(Color.CUSTOM_lightBlue)
        } else {
            content
        }
    }
}

// MARK: - Delete Quantity Bottom Sheet (Wheel Picker)
private struct DeleteQuantitySheet: View {
    let name: String
    let maxQty: Int
    @Binding var selectedQty: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Delete copies of")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Text(name)
                .font(.custom(Font.CUSTOM_MTG_font, size: 22))
                .foregroundColor(Color.CUSTOM_tan)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Wheel picker with MTG custom font + CUSTOM_tan for the counter items
            Picker("Quantity", selection: $selectedQty) {
                ForEach(1...maxQty, id: \.self) { i in
                    Text("×\(i)")
                        .font(.custom(Font.CUSTOM_MTG_font, size: 22))  // <- MTG Custom Font
                        .foregroundColor(Color.CUSTOM_tan)              // <- CUSTOM_tan text color
                        .tag(i)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 110)
            // Also set default styling on the picker (helps some iOS versions)
            .font(.custom(Font.CUSTOM_MTG_font, size: 22))
            .foregroundStyle(Color.CUSTOM_tan)
            .onChange(of: maxQty) { _, newMax in
                selectedQty = min(max(1, selectedQty), newMax)
            }

            HStack(spacing: 12) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                        .foregroundColor(Color.CUSTOM_tan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.CUSTOM_darkBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(action: onConfirm) {
                    Text("Delete")
                        .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 12)
        .background(Color.clear) // background handled by the enclosing ZStack in the .sheet
    }
}

// MARK: - UIKit Share Sheet wrapper
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - ONE smart share item to avoid duplicates
final class CardImageItemSource: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let fileURL: URL?
    private let title: String

    init(image: UIImage, fileURL: URL?, title: String) {
        self.image = image
        self.fileURL = fileURL
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any {
        // Prefer a named file for “save”/Files/Drive/Dropbox/Photos extensions
        if let type = activityType {
            if type == .saveToCameraRoll
                || type == .airDrop
                || type.rawValue.contains("files")      // com.apple.DocumentsApp
                || type.rawValue.contains("Drive")
                || type.rawValue.contains("Dropbox")
                || type.rawValue.lowercased().contains("photos") {
                if let fileURL { return fileURL }
            }
        }
        // Default: UIImage (great for Messages/Mail/Social)
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController,
                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        "MTG Card: \(title)"
    }

    // NOTE: intentionally no link metadata to avoid a second preview bubble in Messages
}

// MARK: - (Optional) Share preview view (kept for reference)
private struct CardSharePreview: View {
    let name: String
    let imageURL: URL

    var body: some View {
        VStack(spacing: 12) {
            Text(name)
                .font(.custom(Font.CUSTOM_MTG_font, size: 40))
                .foregroundColor(Color.CUSTOM_tan)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Color.gray.opacity(0.15))
                        ProgressView()
                    }
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image("DefaultCard").resizable().scaledToFit()
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 6)
            .padding(.horizontal, 20)

            Spacer(minLength: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.CUSTOM_darkBlue)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.CUSTOM_lightBlue, lineWidth: 4)
                )
        )
        .padding(16)
    }
}

// MARK: - Preview
#Preview {
    Card_View(card: .exampleDFC)
}
