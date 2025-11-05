//
//  CardDisplay.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import Foundation

extension Card {
    /// Front-face name for DFCs, or `name` for single-faced
    var displayNameForCollection: String {
        faces?.first?.name ?? name
    }

    /// Best image URL for a given face index (DFC-aware), or single-face art
    func imageURLForFace(index: Int = 0) -> URL? {
        if let faces, faces.indices.contains(index),
           let url = Card.bestURL(from: faces[index].image_uris) {
            return url
        }
        return Card.bestURL(from: image_uris)
    }

    /// Tries common Scryfall keys in a good order
    static func bestURL(from dict: [String: String]?) -> URL? {
        guard let dict else { return nil }
        for key in ["normal", "large", "png", "border_crop", "art_crop", "small"] {
            if let s = dict[key], let u = URL(string: s) { return u }
        }
        return nil
    }
}
