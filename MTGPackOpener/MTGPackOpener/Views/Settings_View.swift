//
//  SettingsView.swift
//  MTGPackOpener
//
//  Created by J.E.D. on 9/21/25.
//

import SwiftUI
import Foundation
import UserNotifications

struct Settings_View: View {
    // MARK: State
    @State private var showAbout = false
    @State private var showRarity = false
    @State private var showRules = false
    @State private var showingConfirmClear = false
    @State private var showingClearedAlert = false

    // Present profile selector (Select_Profiles_View)
    @State private var showProfile = false

    // If selector requests creation, present creator after dismissing selector
    @State private var showCreatorFromSelector = false

    // MARK: Audio Toggles (persisted via SoundManager.Keys)
    @AppStorage(SoundManager.Keys.sfxEnabled)   private var sfxEnabled: Bool = true
    @AppStorage(SoundManager.Keys.musicEnabled) private var musicEnabled: Bool = true

    // MARK: Notifications toggle (persisted)
    @AppStorage("settings.remindersEnabled") private var remindersEnabled: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Header
                ZStack {
                    Rectangle()
                        .fill(Color.CUSTOM_darkBlue)
                        .frame(width: 350, height: 60)
                        .cornerRadius(20)

                    Text(SettingsService.pageTitle)
                        .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                        .foregroundColor(Color.CUSTOM_tan)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .center)

                // MARK: Toggles (Reminders, SFX, Music)
                VStack(spacing: 12) {
                    HStack {
                        Text("Reminders")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                            .foregroundColor(Color.CUSTOM_tan)
                        Spacer()
                        Toggle("", isOn: $remindersEnabled)
                            .labelsHidden()
                            .tint(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)

                    HStack {
                        Text("Sound Effects")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                            .foregroundColor(Color.CUSTOM_tan)
                        Spacer()
                        Toggle("", isOn: $sfxEnabled)
                            .labelsHidden()
                            .tint(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)

                    HStack {
                        Text("Music")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                            .foregroundColor(Color.CUSTOM_tan)
                        Spacer()
                        Toggle("", isOn: $musicEnabled)
                            .labelsHidden()
                            .tint(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                // MARK: Clear Collection (active profile only)
                Button {
                    showingConfirmClear = true
                } label: {
                    HStack {
                        Image(systemName: "trash").imageScale(.medium)
                        Text(SettingsService.clearButtonTitle)
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                    }
                    .foregroundColor(Color.CUSTOM_tan)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                // MARK: About
                Button {
                    showAbout = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle").imageScale(.medium)
                        Text(SettingsService.aboutButtonTitle)
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                    }
                    .foregroundColor(Color.CUSTOM_tan)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                // MARK: Rarity Info
                Button {
                    showRarity = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle").imageScale(.medium)
                        Text(SettingsService.rarityInfoTitle)
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                    }
                    .foregroundColor(Color.CUSTOM_tan)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                // MARK: MTG Rules
                Button {
                    showRules = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle").imageScale(.medium)
                        Text(SettingsService.MTGRulesAndRegulationsTitle)
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                    }
                    .foregroundColor(Color.CUSTOM_tan)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                // MARK: Open Profile Selector
                Button {
                    showProfile = true
                } label: {
                    HStack {
                        Image(systemName: "person.crop.circle").imageScale(.medium)
                        Text("Open Profile")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                    }
                    .foregroundColor(Color.CUSTOM_tan)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(Color.CUSTOM_darkBlue)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 24)
            }
        }
        .background(Color.CUSTOM_lightBlue.ignoresSafeArea())

        // MARK: Confirm clear (active profile only)
        .alert(SettingsService.confirmTitle, isPresented: $showingConfirmClear) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Clear", role: .destructive) {
                CardCollection_Service.clearActive()
                showingClearedAlert = true
            }
        } message: { Text(SettingsService.confirmMessage) }

        .alert(SettingsService.clearedTitle, isPresented: $showingClearedAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(SettingsService.clearedMessage) }

        // MARK: Sheets
        .sheet(isPresented: $showAbout) { About_View() }
        .sheet(isPresented: $showRarity) { RarityInfo_View() }
        .sheet(isPresented: $showRules) { MTGRulesAndReg_View() }

        // MARK: Profile full-screen selector
        .fullScreenCover(isPresented: $showProfile) {
            NavigationStack {
                Select_Profiles_View()
                    .navigationTitle("Select Profile")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showProfile = false }
                        }
                    }
                    .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
                    // Listen for "create profile" requests coming from the selector
                    .onReceive(NotificationCenter.default.publisher(for: .profilesRequestCreate)) { _ in
                        // 1) Close selector
                        showProfile = false
                        // 2) After dismissal completes, present the creator
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showCreatorFromSelector = true
                        }
                    }
            }
        }

        // Create Profile sheet (triggered after selector closes)
        .sheet(isPresented: $showCreatorFromSelector) {
            Profile_View() // create mode
                .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
        }

        // MARK: Audio & Notifications side-effects (iOS 17+ onChange)
        .onChange(of: musicEnabled) { _, newValue in
            SoundManager.shared.setMusicEnabled(newValue, track: "background_music", ext: "mp3")
        }
        .onChange(of: remindersEnabled) { _, newValue in
            if newValue {
                NotificationHandler.shared.ensureDailyReminderScheduled()
            } else {
                // Remove pending local notifications when disabled
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
        .onAppear {
            // Ensure current settings are applied when the view shows
            if remindersEnabled {
                NotificationHandler.shared.ensureDailyReminderScheduled()
            }
            SoundManager.shared.setMusicEnabled(musicEnabled, track: "background_music", ext: "mp3")
        }
    }
}

// MARK: - Preview
#Preview {
    Settings_View()
}
