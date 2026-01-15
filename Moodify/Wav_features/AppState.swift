//
//  AppState.swift
//  Moodify
//
//  Created by rawand salameh on 07/01/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
}
