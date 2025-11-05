//
//  SettingsViewService.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/24/25.
//

import Foundation

// MARK: - SettingsService
struct SettingsService {
    // MARK: Labels
    static let pageTitle = "Settings"
    static let clearButtonTitle = "Clear Card Collection"
    static let aboutButtonTitle = "About Us"
    static let rarityInfoTitle = "Rarity Info"
    static let MTGRulesAndRegulationsTitle = "MTG Rules & Regulations"
    static let confirmTitle = "Are you sure?"
    static let confirmMessage = "This will permanently delete your saved card collection."
    static let clearedTitle = "Card Collection Cleared"
    static let clearedMessage = "Your card collection has been successfully cleared."
    
    
    static func clearCollection() {
        UserDefaults.standard.clearCollection()
    }
}
