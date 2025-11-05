//
//  TabBarButton_View.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/21/25.
//

import Foundation
import SwiftUI

struct TabBarButton: View {
    let index: Int
    @Binding var selectedTab: Int
    let title: String
    let imageName: String   // now custom image
    
    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack {
                Image(imageName)   // custom image from Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(selectedTab == index ? Color.orange : Color.CUSTOM_tan)
                
                Text(title)
                    .font(.custom(Font.CUSTOM_MTG_font, size: 12))
                    .foregroundColor(selectedTab == index ? Color.orange : Color.CUSTOM_tan)
            }
        }
    }
}

