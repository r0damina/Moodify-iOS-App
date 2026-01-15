//
//  PromtText.swift
//  M_GP
//
//  Created by rawand salameh on 21/09/2024.
//

import SwiftUI

struct PromtText: View {
    @State private var textInput: String = "" // State variable to store user input
    @EnvironmentObject var appState: AppState
    @State private var showEmptyInputError = false
    
    var body: some View {
        ZStack {
            // For the whole background color
            LinearGradient(gradient: Gradient(colors: [Color.color5,Color.color1, Color.color5]),
                         startPoint: .topLeading,
                         endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all) // Spread color to corners
            
            VStack(spacing: 20) {
                Text("Enter mood here")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                TextField("How do you feel?", text: $textInput)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal, 30)
                
                Button(action: {
                    //check for no empty field or no spaces
                    guard !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        showEmptyInputError = true
                        return
                            
                        }
                        
                    // Convert input to lowercase and check the value
                    let mood = textInput.lowercased()
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {

                        if mood == "happy" {
                            window.rootViewController = UIHostingController(rootView: HappyView().environmentObject(appState))
                        } else if mood == "sad" {
                            window.rootViewController = UIHostingController(rootView: SadView().environmentObject(appState))
                        }
                        else
                        {
                            window.rootViewController = UIHostingController(rootView: HappyView().environmentObject(appState))
                        }
                    }
                }) {
                    Text("Get Playlist")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.color1)
                        .cornerRadius(10)
                        .padding(.horizontal, 30)
                        .shadow(color: Color.white.opacity(0.7), radius: 10, x: 0, y: 0) // Outer glow
                        .shadow(color: Color.white.opacity(0.4), radius: 10, x: 0, y: 0) // Softer glow
                }
                if showEmptyInputError {
                    Text("Please provide an input")
                        .foregroundColor(.black)
                        .padding()
                }
            }
            
            .padding()
        }
    }
}

#Preview {
    PromtText()
}
