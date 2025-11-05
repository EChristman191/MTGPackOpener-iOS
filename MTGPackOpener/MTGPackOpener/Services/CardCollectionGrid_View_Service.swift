//
//  CardCollectionGrid_View_Service.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/25/25.
//

import Foundation

/// Persists and organizes the user's collected cards.
/// Assumes `CollectedCard` and `Card` conform to `Codable`.
enum CardCollectionGrid_View_Service
{
    private static let storageKey = "CardCollection"

    // MARK: - UX strings for empty state
    static let emptyTitle = "No cards yet"
    static let emptySubtitle = "Open a pack to start your collection."

    // MARK: - Load / Save
    static func load() -> [CollectedCard] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            let items = try JSONDecoder().decode([CollectedCard].self, from: data)
            return items
        } catch {
            print("CardCollectionService.load decode error:", error)
            return []
        }
    }

    static func save(_ items: [CollectedCard]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("CardCollectionService.save encode error:", error)
        }
    }

    // MARK: - Helpers
    /// Sort by card name (A→Z). Customize as needed.
    static func sorted(_ items: [CollectedCard]) -> [CollectedCard] {
        items.sorted { $0.card.name.localizedCaseInsensitiveCompare($1.card.name) == .orderedAscending }
    }

    /// Optional: clear all (for debugging / settings reset)
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
