//
//  LogOut.swift
//  Moodify
//
//  Created by rawand salameh on 07/01/2025.
//

import Foundation
import FirebaseAuth
import SwiftUI
import UIKit

class LogOut: ObservableObject {
    @Published var isLoggedIn = false
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isLoggedIn = user != nil
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: SignInView())
            }
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
