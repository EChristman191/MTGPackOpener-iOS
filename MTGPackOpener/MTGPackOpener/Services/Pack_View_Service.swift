//
//  PackViewService.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/24/25.
//

import Foundation

// MARK: - PackViewService
struct PackViewService {
    // MARK: Configuration
    static let defaultSetQuery = "e:spm"

    // MARK: Networking
    static func fetchPack(size: Int, setQuery: String = defaultSetQuery) async -> [Card] {
        await withTaskGroup(of: Card?.self, returning: [Card].self) { group in
            for _ in 0..<size {
                group.addTask {
                    guard let url = URL(string: "https://api.scryfall.com/cards/random?q=\(setQuery)") else { return nil }
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        return try? JSONDecoder().decode(Card.self, from: data)
                    } catch {
                        return nil
                    }
                }
            }
            var results: [Card] = []
            for await c in group {
                if let c { results.append(c) }
            }
            return results
        }
    }

    // MARK: Persistence
    static func saveToCollection(_ cards: [Card]) {
        var collection = UserDefaults.standard.loadCollection()
        for card in cards {
            if let i = collection.firstIndex(where: { $0.id == card.id }) {
                collection[i].count += 1
            } else {
                collection.append(CollectedCard(id: card.id, card: card, count: 1))
            }
        }
        UserDefaults.standard.saveCollection(collection)
    }
}
