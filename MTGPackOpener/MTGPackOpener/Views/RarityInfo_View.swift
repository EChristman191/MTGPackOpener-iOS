//
//  RarityInfo_View.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/30/25.
//


import SwiftUI

// MARK: - About_View
struct RarityInfo_View: View {
    // MARK: - State
    @State private var RarityLines: [String] = []
    private var PAGE_TITLE = "Rarity Info"
    private var PAGE_VERSION = "MTG Pack Opener"
    private var NAV_TITLE = "Rarity Info"
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                
                // MARK: Header Section
                VStack(spacing: 4) {
                    // App Title
                    Text(PAGE_TITLE)
                        .font(.custom(Font.CUSTOM_MTG_font, size: 30))
                        .foregroundColor(Color.CUSTOM_tan)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // App Version
                    Text(PAGE_VERSION)
                        .font(.subheadline)
                        .foregroundColor(Color.CUSTOM_tan)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

                // Divider between header and body content
                Divider().background(Color.CUSTOM_tan)

                // MARK: About Text Lines
                ForEach(RarityLines, id: \.self) { line in
                    if RarityInfo_View_Service.isHeading(line) {
                        // Headings in About text
                        Text(line)
                            .font(.headline)
                            .bold()
                            .foregroundColor(Color.white)
                            .padding(.top, 8)
                    } else {
                        // Regular body text
                        Text(line)
                            .font(.body)
                            .foregroundColor(Color.white)
                    }
                }

                // MARK: Logo Section
                // Logo image displayed at bottom of About page
                Image("In_App_Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
        }
        .background(Color.CUSTOM_darkBlue) // Page background
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.7), lineWidth: 10) // Light gray border
        )
        .padding()
        .navigationTitle(NAV_TITLE)
        .onAppear {
            // Load About page text from bundled file
            RarityLines = RarityInfo_View_Service.loadAboutText()
        }
    }
}

// MARK: - Preview
#Preview {
    RarityInfo_View()
}
