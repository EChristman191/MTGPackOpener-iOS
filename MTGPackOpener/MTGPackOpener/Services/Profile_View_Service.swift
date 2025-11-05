//
//  Profile_View_Service.swift
//  MTGPackOpener
//
//  Created by [NAME] on [DATE].
//

import Foundation
import UIKit

// MARK: - Persisted Profile Model
struct Profile_View_Model: Codable {
    var id: UUID = UUID()             // Added unique ID
    let email: String
    let username: String
    let avatarJPEG: Data?             // already-compressed JPEG data (optional)
}

// MARK: - Errors
enum Profile_View_Error: LocalizedError {
    case invalidEmail
    case emptyUsername
    case encodeFailed
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .invalidEmail:  return "Please enter a valid email address."
        case .emptyUsername: return "Username can’t be empty."
        case .encodeFailed:  return "Could not save your profile."
        case .decodeFailed:  return "Could not load your saved profile."
        }
    }
}

// MARK: - Profile_View_Service
struct Profile_View_Service {
    // Storage key for the single “last-used” profile
    private static let STORAGE_KEY = "profile.view.model.v1"

    // MARK: - Text Helpers
    static func trim(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValidEmail(_ s: String) -> Bool {
        let trimmed = trim(s)
        guard !trimmed.isEmpty else { return false }
        return trimmed.contains("@") && trimmed.contains(".")
    }

    // MARK: - Image Helpers
    static func uiImage(from data: Data?) -> UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }

    static func compressJPEG(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        image.jpegData(compressionQuality: max(0.0, min(1.0, quality)))
    }

    // MARK: - Suggested Username
    static func suggestedUsername(from email: String) -> String {
        let base = trim(email).components(separatedBy: "@").first ?? ""
        let cleaned = base.replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression)
        return cleaned.isEmpty ? "Player" : cleaned
    }

    // MARK: - Save / Load
    @discardableResult
    static func saveProfile(
        id: UUID? = nil,
        email rawEmail: String,
        username rawUsername: String,
        avatarData: Data?
    ) throws -> Profile_View_Model {

        let email = trim(rawEmail)
        guard isValidEmail(email) else { throw Profile_View_Error.invalidEmail }

        var username = trim(rawUsername)
        if username.isEmpty {
            username = suggestedUsername(from: email)
        }
        guard !username.isEmpty else { throw Profile_View_Error.emptyUsername }

        var finalJPEG: Data? = nil
        if let data = avatarData, let ui = uiImage(from: data) {
            finalJPEG = compressJPEG(ui, quality: 0.8)
        }

        // Keep or create ID
        let model = Profile_View_Model(
            id: id ?? UUID(),
            email: email,
            username: username,
            avatarJPEG: finalJPEG
        )

        // Persist locally
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(model) else {
            throw Profile_View_Error.encodeFailed
        }
        UserDefaults.standard.set(encoded, forKey: STORAGE_KEY)

        // Update shared profiles list (the one the selector reads)
        ProfilesService.upsert(id: model.id, email: email, username: username, avatarData: finalJPEG)

        // Notify listeners (optional)
        NotificationCenter.default.post(name: .profilesActiveChanged, object: nil)

        return model
    }

    static func loadProfile() -> Result<Profile_View_Model?, Error> {
        guard let data = UserDefaults.standard.data(forKey: STORAGE_KEY) else {
            return .success(nil)
        }
        let decoder = JSONDecoder()
        guard let model = try? decoder.decode(Profile_View_Model.self, from: data) else {
            return .failure(Profile_View_Error.decodeFailed)
        }
        return .success(model)
    }

    static func deleteProfile() {
        // Remove the single-view model
        UserDefaults.standard.removeObject(forKey: STORAGE_KEY)

        // Optionally clear the active shared profile
        ProfilesService.setActive(nil)

        // Notify updates
        NotificationCenter.default.post(name: .profilesActiveChanged, object: nil)
    }
}


