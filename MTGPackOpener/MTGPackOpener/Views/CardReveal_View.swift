//
//  CardReveal_View.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/30/25.
//

import Foundation
import SwiftUI

struct CardReveal_View: View {
    // MARK: Inputs
    let cards: [Card]
    let onFinished: () -> Void

    // MARK: Styling
    private let BORDER_RADIUS: CGFloat = 12
    private let BORDER_WIDTH: CGFloat  = 8
    private let CARD_MAX_WIDTH: CGFloat = 360

    // MARK: Colors
    private let DEFAULT_BORDER_COLOR = Color.CUSTOM_lightBlue
    private func rarityWaveColor(for rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common":    return .gray
        case "uncommon":  return .green
        case "rare":      return .blue
        case "mythic":    return .purple
        case "legendary": return .orange
        default:          return .gray
        }
    }

    // MARK: State
    @State private var currentCardIndex = 0
    @State private var currentFaceIndex = 0
    @State private var showingImage = true
    @State private var isAnimating = false

    @State private var BLANK_IMAGE_TEXT = "No image"
    @State private var SKIP_BUTTON_TEXT = "Skip"
    @State private var FLIP_BUTTON_TEXT = "Flip"
    @State private var COMPLETION_MESSAGE = "Pack Complete"

    // MARK: Body
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            if currentCardIndex < cards.count {
                let card = cards[currentCardIndex]
                let waveColor = rarityWaveColor(for: card.rarity)

                VStack(alignment: .leading, spacing: 12) {

                    // Header
                    VStack(spacing: 4) {
                        Text(currentName(for: card))
                            .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                            .foregroundColor(.CUSTOM_tan)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(card.rarity)
                            .font(.subheadline)
                            .foregroundColor(waveColor)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)

                    Divider().background(Color.CUSTOM_tan)

                    // Image
                    if let imageURL = currentImageURL(for: card) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ZstackPlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(63.0/88.0, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: BORDER_RADIUS))
                                    .shadow(radius: 4)
                                    .opacity(showingImage ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.2), value: showingImage)
                            case .failure:
                                RoundedRectangle(cornerRadius: BORDER_RADIUS)
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .imageScale(.large)
                                            .foregroundColor(.gray)
                                    )
                                    .aspectRatio(63.0/88.0, contentMode: .fit)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // No URL at all → fallback bundled image
                        Image("DefaultCard")
                            .resizable()
                            .scaledToFit()
                            .aspectRatio(63.0/88.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: BORDER_RADIUS))
                            .shadow(radius: 4)
                            .opacity(showingImage ? 1 : 0)
                    }

                    // Controls: FLIP (DFC only) + SKIP
                    HStack(spacing: 12) {
                        Spacer()
                        Button {
                            flipCurrentFaceWithFadeSFX()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(FLIP_BUTTON_TEXT)
                                    .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.CUSTOM_darkBlue)
                        .foregroundColor(Color.CUSTOM_tan)
                        .clipShape(Capsule())
                        .disabled(!canFlipCurrentCard)
                        .opacity(canFlipCurrentCard ? 1.0 : 0.5)

                        Button {
                            onFinished()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "forward.fill").imageScale(.small)
                                Text(SKIP_BUTTON_TEXT)
                                    .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color.CUSTOM_darkBlue)
                .clipShape(RoundedRectangle(cornerRadius: BORDER_RADIUS))
                .overlay(
                    RoundedRectangle(cornerRadius: BORDER_RADIUS)
                        .waveStroke(
                            color1: waveColor,
                            color2: DEFAULT_BORDER_COLOR,
                            lineWidth: BORDER_WIDTH,
                            duration: 1.5
                        )
                )
                .frame(maxWidth: CARD_MAX_WIDTH)
                .padding(.horizontal)
                .padding(.top, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap anywhere else = advance (face → next, then next card).
                    advanceWithFadeAndSFX(for: card)
                }
                .onAppear {
                    currentCardIndex = 0
                    currentFaceIndex = 0
                    showingImage = false

                    // Preload SFX for smooth playback
                    SoundManager.shared.preload([
                        ("card_flip_sfx", "mp3"),
                        ("mythic_sfx", "mp3")
                    ])

                    // Fade in first card
                    withAnimation(.easeInOut(duration: 0.25)) { showingImage = true }

                    // Play SFX for the FIRST revealed card
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        let first = (currentCardIndex < cards.count) ? cards[currentCardIndex] : nil
                        playRevealSFX(for: first)
                    }
                }

            } else {
                VStack {
                    Text(COMPLETION_MESSAGE)
                        .font(.custom(Font.CUSTOM_MTG_font, size: 28))
                        .foregroundColor(.CUSTOM_tan)
                        .padding()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onFinished()
                    }
                }
            }
        }
        .background(Color.clear)
    }

    // MARK: Helpers
    private var canFlipCurrentCard: Bool {
        guard currentCardIndex < cards.count else { return false }
        return (cards[currentCardIndex].faces?.count ?? 0) > 1
    }

    private var ZstackPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BORDER_RADIUS)
                .fill(Color.gray.opacity(0.2))
            ProgressView().tint(.white)
        }
        .aspectRatio(63.0/88.0, contentMode: .fit)
    }

    private func currentImageURL(for card: Card) -> URL? {
        if let faces = card.faces, !faces.isEmpty {
            return faces[currentFaceIndex].image_uris?["normal"].flatMap { URL(string: $0) }
        }
        return card.image_uris?["normal"].flatMap { URL(string: $0) }
    }

    private func currentName(for card: Card) -> String {
        if let faces = card.faces, !faces.isEmpty {
            return faces[currentFaceIndex].name
        }
        return card.name
    }

    private func isMythic(_ card: Card) -> Bool {
        card.rarity.lowercased() == "mythic"
    }

    // MARK: SFX Helper (first reveal + mythic sting)
    private func playRevealSFX(for card: Card?) {
        guard let card else { return }
        SoundManager.shared.play("card_flip_sfx", ext: "mp3")
        if isMythic(card) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                SoundManager.shared.play("mythic_sfx", ext: "mp3")
            }
        }
    }

    // MARK: Flip only the current face (no advance to next card)
    private func flipCurrentFaceWithFadeSFX() {
        guard canFlipCurrentCard, !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.2)) { showingImage = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let faces = cards[currentCardIndex].faces, !faces.isEmpty {
                currentFaceIndex = (currentFaceIndex + 1) % faces.count
            }
            withAnimation(.easeInOut(duration: 0.2)) { showingImage = true }
            SoundManager.shared.play("card_flip_sfx", ext: "mp3")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAnimating = false
            }
        }
    }

    // MARK: Advance (face → next, then next card) + SFX
    private func advanceWithFadeAndSFX(for card: Card) {
        guard !isAnimating else { return }
        isAnimating = true
        withAnimation(.easeInOut(duration: 0.25)) { showingImage = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            advanceIndices(for: card)
            withAnimation(.easeInOut(duration: 0.25)) { showingImage = true }

            SoundManager.shared.play("card_flip_sfx", ext: "mp3")
            if currentCardIndex < cards.count, isMythic(cards[currentCardIndex]) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    SoundManager.shared.play("mythic_sfx", ext: "mp3")
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isAnimating = false
            }
        }
    }

    private func advanceIndices(for card: Card) {
        if let faces = card.faces, !faces.isEmpty {
            if currentFaceIndex < faces.count - 1 {
                currentFaceIndex += 1
            } else {
                currentFaceIndex = 0
                currentCardIndex += 1
            }
        } else {
            currentCardIndex += 1
        }
    }
}

// MARK: - Preview
#Preview {
    CardReveal_View(cards: [.example]){}
}
