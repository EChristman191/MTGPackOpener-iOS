//
//  MTGRulesAndReg_View.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import SwiftUI

// MARK: - About_View
struct MTGRulesAndReg_View: View {
    // MARK: - State
    @State private var aboutLines: [String] = []
    private var PAGE_TITLE = "Magic the Gathering"
    private var PAGE_SUBTITLE = "Rules and Regulations"
    private var NAV_TITLE = "MTGRulesAndReg"
    
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
                    Text(PAGE_SUBTITLE)
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
                    if MTGRulesAndReg_View_Service.isHeading(line) {
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
                
                Link(destination: URL(string: "https://www.youtube.com/watch?v=LC95B2XwweA")!) {
                    Text("Video Tutorial")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .foregroundColor(.CUSTOM_tan)
                        .background(Color.CUSTOM_darkBlue)
                        .clipShape(Capsule())
                        .overlay(                           // <- border
                            Capsule().stroke(Color.CUSTOM_tan, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)

                Link(destination: URL(string: "https://media.wizards.com/2025/downloads/M")!) {
                    Text("Official Rules and Regulations")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .foregroundColor(.CUSTOM_tan)
                        .background(Color.CUSTOM_darkBlue)
                        .clipShape(Capsule())
                        .overlay(                           // <- border
                            Capsule().stroke(Color.CUSTOM_tan, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                            
               
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
        // Page background (inside the rounded rectangle)
        .background(Color.CUSTOM_darkBlue)
        // Outer background behind the rounded rectangle
        .background(Color.black.ignoresSafeArea())
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.7), lineWidth: 10) // Light gray border
        )
        .padding()
        .navigationTitle(NAV_TITLE)
        .onAppear
        {
            // Load About page text from bundled file
            aboutLines = MTGRulesAndReg_View_Service.loadAboutText()
        }
    }
}

// MARK: - Preview
#Preview {
    MTGRulesAndReg_View()
}

//https://magic.wizards.com/en/rules
