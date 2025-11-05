//
//  Select_Profiles_View.swift
//  MTGPackOpener
//

import SwiftUI
import PhotosUI

// MARK: - Model
struct ProfileRecord: Identifiable, Codable, Equatable {
    var id: UUID = .init()
    var email: String
    var username: String
    var avatarJPEG: Data?
}

// MARK: - Storage Service
enum ProfilesService {
    private static let kProfiles = "profiles.v1"
    private static let kActiveID = "profiles.active.id"

    static func loadAll() -> [ProfileRecord] {
        guard let data = UserDefaults.standard.data(forKey: kProfiles),
              let arr  = try? JSONDecoder().decode([ProfileRecord].self, from: data)
        else { return [] }
        return arr
    }

    static func saveAll(_ arr: [ProfileRecord]) {
        let data = try? JSONEncoder().encode(arr)
        UserDefaults.standard.set(data, forKey: kProfiles)
    }

    static func setActive(_ id: UUID?) {
        if let id {
            UserDefaults.standard.set(id.uuidString, forKey: kActiveID)
        } else {
            UserDefaults.standard.removeObject(forKey: kActiveID)
        }
        NotificationCenter.default.post(name: .profilesActiveChanged, object: nil)
    }

    static func activeID() -> UUID? {
        guard let s = UserDefaults.standard.string(forKey: kActiveID) else { return nil }
        return UUID(uuidString: s)
    }

    // Upsert by id when provided; otherwise match by email; otherwise create new
    static func upsert(id: UUID?, email: String, username: String, avatarData: Data?) {
        var all = loadAll()

        if let id, let idx = all.firstIndex(where: { $0.id == id }) {
            var rec = all[idx]
            rec.email = email
            rec.username = username
            rec.avatarJPEG = avatarData
            all[idx] = rec
            saveAll(all)
            setActive(rec.id)
            return
        }

        if let idx = all.firstIndex(where: { $0.email.caseInsensitiveCompare(email) == .orderedSame }) {
            var rec = all[idx]
            rec.email = email
            rec.username = username
            rec.avatarJPEG = avatarData
            all[idx] = rec
            saveAll(all)
            setActive(rec.id)
            return
        }

        let rec = ProfileRecord(email: email, username: username, avatarJPEG: avatarData)
        all.append(rec)
        saveAll(all)
        setActive(rec.id)
    }

    static func delete(_ id: UUID) {
        var all = loadAll()
        all.removeAll { $0.id == id }
        saveAll(all)
        if activeID() == id { setActive(loadAll().first?.id) }
    }
}

// MARK: - Select Profiles View
struct Select_Profiles_View: View {
    @State private var profiles: [ProfileRecord]
    @State private var activeID: UUID?

    // Sheets
    @State private var selectedProfile: ProfileRecord? = nil   // EDIT sheet uses .sheet(item:)
    @State private var showCreator: Bool = false               // CREATE sheet via boolean

    private let rowFont: Font = .custom(Font.CUSTOM_MTG_font, size: 18)

    init() {
        _profiles = State(initialValue: ProfilesService.loadAll())
        _activeID = State(initialValue: ProfilesService.activeID())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.CUSTOM_lightBlue.ignoresSafeArea()

                if profiles.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(profiles) { p in
                            ProfileRow_View(
                                profile: p,
                                isActive: p.id == activeID,
                                rowFont: rowFont,
                                tan: Color.CUSTOM_tan,
                                darkRow: Color.CUSTOM_darkBlue
                            ) {
                                if activeID != p.id {
                                    // First tap on a different profile → just select it
                                    ProfilesService.setActive(p.id)
                                    activeID = p.id
                                } else {
                                    // Tap again on the active profile → EDIT it
                                    selectedProfile = p
                                }
                            }
                        }
                        .onDelete(perform: handleDelete)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Select Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Open creator (blank)
                        showCreator = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.CUSTOM_tan)
                    }
                    .accessibilityLabel("Add Profile")
                }
            }
            .tint(Color.CUSTOM_tan)
        }
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .profilesActiveChanged)) { _ in
            // Keep UI in sync if active changes elsewhere
            activeID = ProfilesService.activeID()
        }

        // EDIT sheet (only when selectedProfile is non-nil)
        .sheet(item: $selectedProfile, onDismiss: reload) { p in
            Profile_View(profileID: p.id,
                         email: p.email,
                         username: p.username,
                         avatarData: p.avatarJPEG)
                .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
        }

        // CREATE sheet (always blank)
        .sheet(isPresented: $showCreator, onDismiss: reload) {
            Profile_View()
                .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
        }
    }

    private func handleDelete(_ indexSet: IndexSet) {
        // Delete the tapped rows
        let idsToDelete = indexSet.map { profiles[$0].id }
        idsToDelete.forEach { ProfilesService.delete($0) }

        // Refresh local state
        profiles = ProfilesService.loadAll()

        if let first = profiles.first {
            // Force-select the top profile
            ProfilesService.setActive(first.id)
            activeID = first.id
        } else {
            // No profiles left: clear active and force creation flow
            ProfilesService.setActive(nil)
            showCreator = true
        }

        // Clean up any stale edit selection
        if let sel = selectedProfile, !profiles.contains(where: { $0.id == sel.id }) {
            selectedProfile = nil
        }
    }

    private func reload() {
        profiles = ProfilesService.loadAll()
        activeID  = ProfilesService.activeID()
        // Clear any stale selection
        if let sel = selectedProfile, !profiles.contains(where: { $0.id == sel.id }) {
            selectedProfile = nil
        }
    }
}

// MARK: - Row View
private struct ProfileRow_View: View {
    let profile: ProfileRecord
    let isActive: Bool
    let rowFont: Font
    let tan: Color
    let darkRow: Color
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AvatarView(data: profile.avatarJPEG)
                    .frame(width: 46, height: 46)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))

                Text(profile.username)
                    .font(rowFont)
                    .foregroundColor(tan)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .listRowBackground(darkRow)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Avatar View
private struct AvatarView: View {
    let data: Data?
    var body: some View {
        Group {
            if let data, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .foregroundColor(Color.CUSTOM_tan.opacity(0.8))
            }
        }
    }
}

// MARK: - Empty State
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.5))
            Text("No Profiles Yet")
                .font(.custom(Font.CUSTOM_MTG_font, size: 22))
                .foregroundColor(Color.CUSTOM_tan)
            Text("Tap + to create your first profile.")
                .font(.custom(Font.CUSTOM_MTG_font, size: 16))
                .foregroundColor(Color.CUSTOM_tan.opacity(0.8))
        }
    }
}
