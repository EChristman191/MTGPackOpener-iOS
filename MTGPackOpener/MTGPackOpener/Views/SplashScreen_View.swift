//
//  SplashScreen_View.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/21/25.
//

import Foundation
import SwiftUI

struct SplashScreen: View {
    @EnvironmentObject var net: NetworkMonitor
    @Binding var showMainApp: Bool
    @State private var showNoInternetAlert = false
    @State private var isFading = false                  // quick fade-out state

    private let BUTTON_TEXT_ONLINE  = "Tap to continue"
    private let BUTTON_TEXT_OFFLINE = "No internet"

    var body: some View {
        ZStack {
            // Background layer that handles the tap
            Color.CUSTOM_lightBlue
                .ignoresSafeArea()
                .contentShape(Rectangle())               // makes whole area tappable
                .onTapGesture {
                    if net.isConnected {
                        // trigger a quick fade, then advance
                        withAnimation(.easeInOut(duration: 0.2)) { isFading = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut) {
                                showMainApp = true
                            }
                        }
                    } else {
                        showNoInternetAlert = true
                    }
                }

            // Call-to-action pill (non-interactive visual)
            Rectangle()
                .fill(Color.CUSTOM_darkBlue.gradient)
                .frame(width: 350, height: 60)
                .cornerRadius(20)
                .padding(.top, 700)
                .allowsHitTesting(false)

            // Your app logo stays centered
            AppLogo()

            // CTA text reflects connectivity
            VStack {
                Text(net.isConnected ? BUTTON_TEXT_ONLINE : BUTTON_TEXT_OFFLINE)
                    .font(.custom(Font.CUSTOM_MTG_font, size: 25))
                    .foregroundColor(Color.CUSTOM_tan)
                    .padding(.top, 700)
                    .opacity(net.isConnected ? 1.0 : 0.7)
            }
        }.safeAreaInset(edge: .top) {
            if !net.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                    Text("You’re offline. Connect to Wi-Fi or cellular to continue.")
                }
                .font(.footnote)
                .foregroundColor(Color.CUSTOM_tan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.CUSTOM_darkBlue)   // stays under the notch/status bar
            }
        }
        // Friendly alert to guide the user
        .alert("No Internet Connection", isPresented: $showNoInternetAlert) {
            Button("OK", role: .cancel) {}
            Button("Settings") { NetworkMonitor.openSettings() }
        } message: {
            Text("Please connect to the internet to continue.")
        }
        .opacity(isFading ? 0 : 1)                     // apply the quick fade-out
    }
}
