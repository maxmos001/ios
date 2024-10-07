//
//  SessionData.swift
//  BlockScribe
//
//  Created by Alex Lin on 17/6/24.
//

import Foundation
import SwiftUI
import Combine
import KindeSDK

class SessionData: ObservableObject {    
    @Published var isScrollEnabled: Bool = false
    @Published var fileURL: URL?
    @Published var sharedFileURL: URL?
    @Published var user: UserProfile?
}
