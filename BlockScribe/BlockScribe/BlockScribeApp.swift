//
//  BlockScribeApp.swift
//  BlockScribe
//
//  Created by Alex Lin on 9/3/24.
//

import SwiftUI

@main
struct BlockScribeApp: App {
    var sessionData = SessionData()
    var body: some Scene {
        WindowGroup {
            AppView()
                .environmentObject(sessionData)
        }
    }
}
