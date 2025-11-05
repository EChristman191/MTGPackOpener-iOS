//
//  AppLogo_View.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/21/25.
//

import Foundation
import SwiftUI

struct AppLogo: View {
    var body: some View {
        Image("In_App_Logo") // name from Assets
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 250)
            .cornerRadius(20)
            .shadow(radius: 10)
            .allowsHitTesting(false)
    }
}
