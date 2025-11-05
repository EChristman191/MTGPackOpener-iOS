//
//  PackView.swift
//  MTGPackOpener
//

import Foundation
import SwiftUI

private let PACK_SIZE = 14

// MARK: - PackView
struct Pack_View: View {
    // MARK: State
    @State private var cards: [Card] = []
    @State private var showingReveal = false
    @State private var isOpening = false
    @State private var revealSessionID = UUID()
    
    @State private var TITLE = "MTG Pack Opener"
    @State private var BUTTON_MESSAGE = "Tap To Open"
    @State private var OPENING_STATUS = "Opening..."

    // MARK: Body
    var body: some View {
        ZStack {
            Color.CUSTOM_lightBlue.ignoresSafeArea()
            VStack {
                ScrollView {
                    Text(TITLE)
                        .padding()
                        .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                        .foregroundColor(Color.CUSTOM_tan)
                        .background(Color.CUSTOM_darkBlue)
                        .cornerRadius(20)

                    Button {
                        Task { await openBoosterPack() }
                    } label: {
                        ZStack {
                            Image("SMPack")
                                .resizable()
                                .frame(width: 350, height: 600)
                                .cornerRadius(10)
                                .shadow(radius: 8)

                            Text(isOpening ? OPENING_STATUS : BUTTON_MESSAGE)
                                .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                                .foregroundColor(Color.CUSTOM_tan)
                                .shadow(radius: 5)
                                .padding(.bottom, 540)
                        }
                    }
                    .disabled(isOpening)
                    .padding(.bottom, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showingReveal) {
            CardReveal_View(cards: cards) {
                cards.removeAll()
                showingReveal = false
            }
            .id(revealSessionID)
            .background(Color.clear)
            .presentationBackground(.clear)
        }
    }

    // MARK: Networking
    @MainActor
    func openBoosterPack() async {
        guard !isOpening else { return }
        isOpening = true
        cards.removeAll()

        let fetched = await PackViewService.fetchPack(size: PACK_SIZE)
        print("Fetched cards: \(fetched.count)")   // debug

        guard !fetched.isEmpty else {
            isOpening = false
            print("No cards fetched")
            return
        }

        // Use up to PACK_SIZE cards
        let pack = Array(fetched.prefix(PACK_SIZE))

        // === Save to the ACTIVE PROFILE’s collection ===
        CardCollection_Service.append(cards: pack)

        cards = pack
        revealSessionID = UUID()
        showingReveal = true
        isOpening = false
        print("Presenting reveal with \(cards.count) cards")
    }
}

// MARK: - Preview
#Preview {
    Root_View()
}
