//
//  CardFace.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import Foundation
import SwiftUI

//JSON Format for Swift
//Gets id, name, and image_uris from Scryfall and stores it inside the Structure
struct CardFace: Codable, Identifiable {
    let id = UUID()
    let name: String
    let image_uris: [String: String]?
}

#Preview {
    Root_View()
}
