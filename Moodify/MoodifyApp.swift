//
//  MoodifyApp.swift
//  Moodify
//
//  Created by rawand salameh on 23/09/2024.
//

import SwiftUI

import FirebaseCore

import FirebaseAnalytics

import FirebaseFirestore

import FirebaseFirestoreInternal



//for life cycle events
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        //Set Firebase logging level
        FirebaseConfiguration.shared.setLoggerLevel(.debug)

        // Configure Firebase
        FirebaseApp.configure()//connects app to firebase services using google info plist

        //Set the data collection flag to true
        Analytics.setAnalyticsCollectionEnabled(true) // Set to false to disable data collection

        return true
    }
}

@main
struct MoodifyApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var modelManager = ModelManager()//model manager instance
    @StateObject private var appState = AppState()
   
    var body: some Scene {
        WindowGroup {
            NavigationView {
                //start with content view and send the observable objects
                ContentView()
                    .environmentObject(modelManager)
                    .environmentObject(appState)
                
                
                     if appState.isLoggedIn {
                                ViewTwo()
                                    .environmentObject(appState)
                            } else {
                                SignInView()
                                    .environmentObject(appState)
                            }
                   
                
                   
            }
        }
    }
}
