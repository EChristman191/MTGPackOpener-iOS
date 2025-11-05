//
//  Main_View.swift
//  MTGPackOpener
//
//  Created by J.E.D. on 9/21/25.
//

import SwiftUI

// MARK: - Collection mode
private enum CollectionMode { case grid, list }

// MARK: - Main_View
struct Main_View: View {
    // Tabs
    @State private var selectedTab: Int = 0
    // Grid/List toggle
    @State private var collectionMode: CollectionMode = .grid

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: Main Content
            Group {
                switch selectedTab {
                case 0:
                    Pack_View()

                case 1:
                    Group {
                        switch collectionMode {
                        case .grid: CardCollectionGrid_View()
                        case .list: CardCollectionList_View()
                        }
                    }

                case 2:
                    Settings_View()

                default:
                    Pack_View()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.CUSTOM_lightBlue)

            // Floating toggle button appears only on the "Cards" tab
            if selectedTab == 1 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ToggleViewButton(isGrid: collectionMode == .grid) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                collectionMode = (collectionMode == .grid) ? .list : .grid
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 80) // keep above tab bar
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // MARK: Custom Tab Bar
            HStack {
                TabBarButton(index: 0,
                             selectedTab: $selectedTab,
                             title: "Packs",
                             imageName: "Open_Packs_ICON")

                Spacer()

                TabBarButton(index: 1,
                             selectedTab: $selectedTab,
                             title: "Cards",
                             imageName: "cards_ICON")

                Spacer()

                TabBarButton(index: 2,
                             selectedTab: $selectedTab,
                             title: "Settings",
                             imageName: "settings_ICON")
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 12)
            .background(Color.CUSTOM_darkBlue)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Floating toggle button
private struct ToggleViewButton: View {
    let isGrid: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                .font(.system(size: 18, weight: .semibold))
                .padding(14)
                .background(
                    Circle()
                        .fill(Color.CUSTOM_darkBlue)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                )
                .foregroundColor(Color.CUSTOM_tan)
                .accessibilityLabel(isGrid ? "Switch to list view" : "Switch to grid view")
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    Main_View()
}
