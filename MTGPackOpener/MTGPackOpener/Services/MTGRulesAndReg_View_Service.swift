//
//  MTGRulesAndReg_View_Service.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 10/10/25.
//


import Foundation

// MARK: - AboutViewService
struct MTGRulesAndReg_View_Service {
    // MARK: Load File
    static func loadAboutText() -> [String] {
        if let path = Bundle.main.path(forResource: "MTGRulesAndReg", ofType: "txt") {
            if let content = try? String(contentsOfFile: path) {
                return content.components(separatedBy: .newlines)
            }
        }
        return []
    }

    // MARK: Heading Detection
    static func isHeading(_ line: String) -> Bool {
        let headings = [
            "Magic: The Gathering — The Basics",
            "Core Concepts",
            "Summary",
            "Helpful Resources"
        ]
        return headings.contains(line.trimmingCharacters(in: .whitespacesAndNewlines))
        
    }
}
