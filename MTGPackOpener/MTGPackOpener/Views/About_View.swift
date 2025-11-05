//
//  AboutView.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import SwiftUI

// MARK: - About_View
struct About_View: View {
    // MARK: - State
    @State private var aboutLines: [String] = []
    private var PAGE_TITLE = "About Us"
    private var PAGE_VERSION = "Ver. 1.0.0"
    private var NAV_TITLE = "About Us"
    
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
                ForEach(aboutLines, id: \.self) { line in
                    if AboutViewService.isHeading(line) {
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
            aboutLines = AboutViewService.loadAboutText()
        }
    }
}

// MARK: - Preview
#Preview {
    About_View()
}
