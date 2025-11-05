//
//  Root_View.swift
//  MTGPackOpener
//

import SwiftUI
import UserNotifications
import UIKit

private enum AppStage { case splash, selectProfile, main }

struct Root_View: View {
    // App stage machine
    @State private var stage: AppStage = .splash

    // Bridge for SplashScreen’s Binding<Bool>
    @State private var proceedFromSplash: Bool = false

    // Track which profile is active; drives auto-advance
    @State private var activeID: UUID? = ProfilesService.activeID()

    init() {
        NotificationHandler.shared.configure()
    }

    var body: some View {
        ZStack {
            switch stage {
            // 1) Splash
            case .splash:
                SplashScreen(showMainApp: $proceedFromSplash)
                    .environmentObject(NetworkMonitor.shared)
                    .onChange(of: proceedFromSplash) { _, go in
                        if go {
                            stage = .selectProfile
                            NotificationHandler.shared.requestAuthorizationAndScheduleDailyNoonReminder()
                            proceedFromSplash = false
                        }
                    }

            // 2) Select / Create Profile
            case .selectProfile:
                NavigationStack {
                    Select_Profiles_View()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Continue") {
                                    withAnimation(.easeInOut(duration: 0.35)) { stage = .main }
                                }
                                .font(.custom(Font.CUSTOM_MTG_font, size: 18))
                                .foregroundColor(Color.CUSTOM_tan)
                                .disabled(activeID == nil)
                                .opacity(activeID == nil ? 0.4 : 1.0)
                                .accessibilityHint("Select a profile to continue")
                            }
                        }
                }
                .onAppear { activeID = ProfilesService.activeID() }
                .onReceive(NotificationCenter.default.publisher(for: .profilesActiveChanged)) { _ in
                    activeID = ProfilesService.activeID()
                }
                .onAppear(perform: refreshActive)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    refreshActive()
                }
                .onChange(of: activeID) { _, newID in
                    if newID != nil {
                        withAnimation(.easeInOut(duration: 0.35)) { stage = .main }
                    }
                }
                .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading)))

            // 3) Main App
            case .main:
                Main_View()
                    .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .identity))
            }
        }
        .background(Color.CUSTOM_lightBlue.ignoresSafeArea())
        .onAppear {
            // If an active profile already exists, you can skip selection:
            // if ProfilesService.activeID() != nil { stage = .main }
        }
        .animation(.easeInOut(duration: 0.35), value: stage)
    }

    private func refreshActive() {
        activeID = ProfilesService.activeID()
    }
}
