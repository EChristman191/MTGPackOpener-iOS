import Foundation

// MARK: - CardCollection Service (per active profile)
struct CardCollection_Service {
    private static let legacyKey = "collection.v1"
    private static func key(for id: UUID?) -> String { "collection.v1.\(id?.uuidString ?? "no-profile")" }

    // Load raw collection for ACTIVE profile (includes legacy migration)
    static func load() -> [CollectedCard] {
        let active = ProfilesService.activeID()
        let scopedKey = key(for: active)
        let defaults = UserDefaults.standard

        // Migrate old global collection into current profile bucket once
        if let data = defaults.data(forKey: legacyKey),
           defaults.data(forKey: scopedKey) == nil {
            defaults.set(data, forKey: scopedKey)
            defaults.removeObject(forKey: legacyKey)
        }

        guard let data = defaults.data(forKey: scopedKey) else { return [] }
        return (try? JSONDecoder().decode([CollectedCard].self, from: data)) ?? []
    }

    // Save collection for ACTIVE profile (writes the *normalized* array)
    static func save(_ collection: [CollectedCard]) {
        let active = ProfilesService.activeID()
        let scopedKey = key(for: active)
        let normalized = normalize(collection)               // <<< merge duplicates here
        let data = try? JSONEncoder().encode(normalized)
        UserDefaults.standard.set(data, forKey: scopedKey)
    }

    // For UI usage: always return a *normalized* & optionally sorted list
    static func normalizedSorted() -> [CollectedCard] {
        sorted(normalize(load()))
    }

    // Sorting: rarity then name
    static func sorted(_ c: [CollectedCard]) -> [CollectedCard] {
        c.sorted {
            if $0.card.rarityOrder == $1.card.rarityOrder { return $0.card.name < $1.card.name }
            return $0.card.rarityOrder < $1.card.rarityOrder
        }
    }
}

// MARK: - Public helpers (use normalized data everywhere)
extension CardCollection_Service {
    static func clearActive() {
        save([]) // save() normalizes anyway
        NotificationCenter.default.post(name: .cardsCollectionChanged, object: nil)
    }

    /// Append newly opened cards. If the "same card" exists, increment its count.
    static func append(cards newCards: [Card]) {
        var current = load()
        for c in newCards {
            // find by identity (robust)
            if let idx = current.firstIndex(where: { isSameCard($0.card, c) }) {
                current[idx].count += 1
            } else {
                current.append(CollectedCard(id: UUID().uuidString, card: c, count: 1))
            }
        }
        save(current) // save() will normalize/merge any lingering dupes
        NotificationCenter.default.post(name: .cardsCollectionChanged, object: nil)
    }

    /// Total copies of `card` (sums across rows sharing identity).
    static func count(for card: Card) -> Int {
        let key = identityKey(for: card)
        // Work off normalized(load()) so legacy dupes are merged before counting
        return normalize(load()).reduce(0) { acc, cc in
            identityKey(for: cc.card) == key ? acc + cc.count : acc
        }
    }

    /// Remove one copy.
    static func deleteOne(matching target: Card) -> Bool {
        delete(matching: target, quantity: 1) > 0
    }

    /// Remove `quantity` copies (clamped to available), across all matching rows.
    /// Returns actual number removed.
    static func delete(matching target: Card, quantity: Int) -> Int {
        guard quantity > 0 else { return 0 }
        var current = normalize(load())  // start from a merged snapshot
        let key = identityKey(for: target)

        guard let idx = current.firstIndex(where: { identityKey(for: $0.card) == key }) else {
            return 0
        }

        let available = current[idx].count
        let remove = min(quantity, available)
        current[idx].count = available - remove
        if current[idx].count == 0 { current.remove(at: idx) }

        save(current) // save normalized back
        NotificationCenter.default.post(name: .cardsCollectionChanged, object: nil)
        return remove
    }

    static var emptyTitle: String { "No boosters cracked yet." }
    static var emptySubtitle: String { "Open a pack to begin your collection." }
}

// MARK: - Normalization / Identity
private extension CardCollection_Service {
    /// Merge duplicate entries that represent the same card (sum `count`).
    /// Keeps the first encountered `CollectedCard`’s `card` payload.
    static func normalize(_ arr: [CollectedCard]) -> [CollectedCard] {
        var buckets: [String: CollectedCard] = [:]
        for item in arr {
            let k = identityKey(for: item.card)
            if var existing = buckets[k] {
                existing.count += item.count
                buckets[k] = existing
            } else {
                buckets[k] = item
            }
        }
        return Array(buckets.values)
    }

    /// Robust identity for a card. Prefer set+collector_number when available;
    /// otherwise fall back to a normalized name (case/whitespace/diacritics/dashes normalized).
    static func identityKey(for c: Card) -> String {
        // If your Card model exposes `set` and `collector_number`, this is best:
        // if let set = c.set, let num = c.collector_number {
        //     return "set:\(set.lowercased())#\(num.lowercased())"
        // }

        let dashed = c.name
            .replacingOccurrences(of: "–", with: "-")  // en dash
            .replacingOccurrences(of: "—", with: "-")  // em dash
            .replacingOccurrences(of: "−", with: "-")  // minus
        let folded = dashed.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                    locale: .current)
        let squashed = folded.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return squashed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isSameCard(_ a: Card, _ b: Card) -> Bool {
        identityKey(for: a) == identityKey(for: b)
    }
}
