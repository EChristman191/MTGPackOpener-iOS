//
//  RarityInfo_View_Service.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/30/25.
//

import Foundation

// MARK: - AboutViewService
struct RarityInfo_View_Service {
    
    // MARK: Load File
    static func loadAboutText() -> [String] {
        if let path = Bundle.main.path(forResource: "RarityInfo", ofType: "txt") {
            if let content = try? String(contentsOfFile: path) {
                return content.components(separatedBy: .newlines)
            }
        }
        return []
    }

    // MARK: Heading Detection
    static func isHeading(_ line: String) -> Bool {
        let headings = [
            "Description",
            "Common — Gray",
            "Uncommon — Blue / Silver",
            "Rare — Gold",
            "Mythic Rare — Orange / Red-Orange",
            "Legendary / Special Printings (optional tier) — Purple",
            "Summary"
        ]
        return headings.contains(line.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
