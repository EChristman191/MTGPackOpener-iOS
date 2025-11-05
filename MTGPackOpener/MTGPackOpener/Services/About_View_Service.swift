//
//  AboutViewService.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/24/25.
//

import Foundation

// MARK: - AboutViewService
struct AboutViewService {
    // MARK: Load File
    static func loadAboutText() -> [String] {
        if let path = Bundle.main.path(forResource: "AboutMe", ofType: "txt") {
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
            "Contact Us",
            "Meet our team!",
            "Acknowledgements",
            "LEGAL INFORMATION",
            "Accessibility"
        ]
        return headings.contains(line.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
