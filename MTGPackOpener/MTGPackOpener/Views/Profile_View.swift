//
//  Profile_View.swift
//  MTGPackOpener
//

import SwiftUI
import PhotosUI

struct Profile_View: View {
    // MARK: Incoming (nil = create new)
    private let profileID: UUID?

    // MARK: Form state
    @State private var email: String
    @State private var username: String
    @State private var avatarData: Data?
    @State private var pickerItem: PhotosPickerItem?

    // MARK: UX state
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var canDismiss = true

    @State private var showDiscardConfirm = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage: String?

    @State private var showDeleteConfirm = false
    @State private var showDeleteSuccess = false

    // Init allows both create and edit entry points
    init(profileID: UUID? = nil, email: String = "", username: String = "", avatarData: Data? = nil) {
        self.profileID = profileID
        _email = State(initialValue: email)
        _username = State(initialValue: username)
        _avatarData = State(initialValue: avatarData)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.CUSTOM_lightBlue.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Title
                        Text(profileID == nil ? "Create Profile" : "Edit Profile")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                            .foregroundColor(Color.CUSTOM_tan)
                            .padding(.top, 8)

                        // Avatar + picker
                        HStack(spacing: 12) {
                            avatarCircle
                                .frame(width: 64, height: 64)
                                .background(Color.CUSTOM_darkBlue.opacity(0.5))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

                            Spacer(minLength: 12)

                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Text("Upload Profile Picture")
                                    .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                                    .foregroundColor(Color.CUSTOM_tan)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Color.CUSTOM_lightBlue)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.CUSTOM_darkBlue)
                                .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal)

                        // Fields
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.custom(Font.CUSTOM_MTG_font, size: 14))
                                    .foregroundColor(Color.CUSTOM_tan.opacity(0.9))
                                TextField("you@example.com", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .padding(12)
                                    .background(Color.CUSTOM_lightBlue.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username")
                                    .font(.custom(Font.CUSTOM_MTG_font, size: 14))
                                    .foregroundColor(Color.CUSTOM_tan.opacity(0.9))
                                TextField("Enter a username", text: $username)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .padding(12)
                                    .background(Color.CUSTOM_lightBlue.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.CUSTOM_darkBlue))
                        .padding(.horizontal)

                        // Actions
                        HStack(spacing: 12) {
                            if canDismiss {
                                Button {
                                    showDiscardConfirm = true
                                } label: {
                                    Text("Cancel")
                                        .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                                        .foregroundColor(Color.CUSTOM_tan)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.CUSTOM_darkBlue)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }

                            Button {
                                saveProfile()
                            } label: {
                                HStack(spacing: 8) {
                                    if isSaving { ProgressView().tint(Color.CUSTOM_tan) }
                                    Text("Save")
                                }
                                .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                                .foregroundColor(Color.CUSTOM_tan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.CUSTOM_darkBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isSaving)
                        }
                        .padding(.horizontal)

                        if profileID != nil {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Text("Delete Profile")
                                    .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.18))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .disabled(!canDismiss)
                        .opacity(canDismiss ? 1 : 0.4)
                }
            }
        }
        // Block swipe-to-dismiss when no profiles exist
        .interactiveDismissDisabled(!canDismiss)

        // Alerts
        .alert("Discard changes?", isPresented: $showDiscardConfirm) {
            Button("Keep Editing", role: .cancel) { }
            Button("Discard", role: .destructive) { dismiss() }
        } message: { Text("Your changes will not be saved.") }

        .alert("Profile Saved", isPresented: $showSaveSuccess) {
            Button("OK") { dismiss() }
        } message: { Text("Your profile has been saved successfully.") }

        .alert("Couldn’t Save", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: { Text(saveErrorMessage ?? "Something went wrong.") }

        .alert("Delete Profile?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { performDelete() }
        } message: { Text("This will permanently remove the profile.") }

        .alert("Profile Deleted", isPresented: $showDeleteSuccess) {
            Button("OK") {
                // If none remain, keep sheet open in create state and keep Close disabled
                if ProfilesService.loadAll().isEmpty {
                    canDismiss = false
                    // stay on this view (now blank) so user must create a new one
                } else {
                    canDismiss = true
                    dismiss()
                }
            }
        } message: { Text("Your profile has been deleted.") }

        // Photo loader
        .task(id: pickerItem) {
            guard let item = pickerItem else { return }
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run { avatarData = data }
            }
        }
        .onAppear {
            // Disable closing if there are NO profiles at all
            canDismiss = !ProfilesService.loadAll().isEmpty
        }
    }

    // MARK: - Subviews
    private var avatarCircle: some View {
        Group {
            if let avatarData, let ui = UIImage(data: avatarData) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundColor(Color.CUSTOM_tan.opacity(0.9))
            }
        }
    }

    // MARK: - Actions
    private func saveProfile() {
        isSaving = true
        defer { isSaving = false }

        var finalUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if finalUsername.isEmpty {
            finalUsername = email.split(separator: "@").first.map(String.init) ?? "Player"
            username = finalUsername
        }

        // Persist via ProfilesService used by the selector
        ProfilesService.upsert(id: profileID,
                               email: email,
                               username: finalUsername,
                               avatarData: avatarData)

        // At least one profile now exists → allow dismiss
        canDismiss = true
        showSaveSuccess = true
    }

    private func performDelete() {
        if let id = profileID {
            ProfilesService.delete(id)
        }

        // If nothing remains, lock dismiss and reset to create state
        let anyProfilesLeft = !ProfilesService.loadAll().isEmpty
        canDismiss = anyProfilesLeft

        // Reset fields to "create new"
        email = ""
        username = ""
        avatarData = nil
        pickerItem = nil

        showDeleteSuccess = true
    }
}

// MARK: - Preview
#Preview {
    // Create mode preview
    Profile_View()
}
