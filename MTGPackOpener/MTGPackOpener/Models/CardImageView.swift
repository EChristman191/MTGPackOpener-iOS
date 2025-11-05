//
//  CardImageView.swift
//  MTGPackOpener
//
//  Created by J.E.D.
//

import SwiftUI

struct CardImageView: View {
    let imageURIs: [String: String]?

    private func bestURL() -> URL? {
        guard let dict = imageURIs else { return nil }
        for key in ["normal", "large", "small", "png", "border_crop", "art_crop"] {
            if let s = dict[key], let u = URL(string: s) { return u }
        }
        return nil
    }

    var body: some View {
        let url = bestURL()
        AsyncImage(url: url, transaction: .init(animation: .easeIn(duration: 0.2))) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 60, height: 85)
                    .overlay(ProgressView())
                    .cornerRadius(6)

            case .success(let image):
                image.resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 85)
                    .cornerRadius(6)
                    .shadow(radius: 2)
                    .transition(.opacity)

            case .failure(_):
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 85)
                    .overlay(
                        Text("?")
                            .font(.custom(Font.CUSTOM_MTG_font, size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    )
                    .cornerRadius(6)

            @unknown default:
                EmptyView()
            }
        }
    }
}
