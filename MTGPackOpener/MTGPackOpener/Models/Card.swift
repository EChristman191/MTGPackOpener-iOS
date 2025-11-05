//
//  Card.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import Foundation
import SwiftUI

// MARK: - Card
struct Card: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let faces: [CardFace]?
    let image_uris: [String: String]?
    let rarity: String

    enum CodingKeys: String, CodingKey {
        case id, name, rarity, image_uris
        case faces = "card_faces"    // <- critical for DFCs
    }

    static func == (lhs: Card, rhs: Card) -> Bool { lhs.id == rhs.id }
}

// MARK: - Card (Helpers)
extension Card {
    /// Your existing rarity sort order
    var rarityOrder: Int
    {
        switch rarity.lowercased() {
        case "mythic": return 0
        case "rare": return 1
        case "uncommon": return 2
        case "common": return 3
        default: return 4
        }
    }
}

// MARK: - CollectedCard
struct CollectedCard: Codable, Identifiable, Equatable {
    let id: String       // same as card.id
    let card: Card
    var count: Int

    static func == (lhs: CollectedCard, rhs: CollectedCard) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Persistence
extension UserDefaults {
    private static let collectionKey = "cardsInCollection"

    func saveCollection(_ collection: [CollectedCard]) {
        if let data = try? JSONEncoder().encode(collection) {
            set(data, forKey: UserDefaults.collectionKey)
        }
    }

    func loadCollection() -> [CollectedCard] {
        if let data = data(forKey: UserDefaults.collectionKey),
           let decoded = try? JSONDecoder().decode([CollectedCard].self, from: data) {
            return decoded
        }
        return []
    }

    func clearCollection() -> [CollectedCard] {
        // removeObject(forKey: UserDefaults.collectionKey)
        return []
    }
}

// MARK: - Example
extension Card {
    static var example: Card {
        Card(
            id: "example-black-lotus",
            name: "Black Lotus",
            faces: nil, // single-faced card
            image_uris: ["normal": "https://example.com/lotus.jpg"],
            rarity: "mythic"
        )
    }

    // Optional: double-faced example to test your UI
    static var exampleDFC: Card {
        Card(
            id: "example-delver",
            name: "Delver of Secrets // Insectile Aberration",
            faces: [
                CardFace(name: "Delver of Secrets",
                         image_uris: ["normal": "https://example.com/delver-front.jpg"]),
                CardFace(name: "Insectile Aberration",
                         image_uris: ["normal": "https://example.com/delver-back.jpg"])
            ],
            image_uris: nil, // DFCs typically don't have top-level image_uris
            rarity: "common"
        )
    }
}




#Preview {
    Root_View()
}
