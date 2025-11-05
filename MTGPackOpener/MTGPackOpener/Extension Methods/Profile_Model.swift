//
//  Profile_Model.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import Foundation

// MARK: - ProfileModel
struct ProfileModel: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String
    var username: String
    var avatarImageData: Data?

    init(id: UUID = UUID(),
         email: String,
         username: String,
         avatarImageData: Data? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.avatarImageData = avatarImageData
    }

    // MARK: Derived
    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedUsername: String { username.trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Example
extension ProfileModel {
    static var example: ProfileModel {
        ProfileModel(email: "player@example.com", username: "Planeswalker", avatarImageData: nil)
    }
}

