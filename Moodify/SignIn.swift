//
//  SignIn.swift
//  Moodify
//
//  Created by rawand salameh on 11/10/2024.
//

import SwiftUI
import FirebaseAuth

struct SignInView: View {
    // Variables to store the email, password, and any error message
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @EnvironmentObject var appState: AppState
    var body: some View {
        ZStack {
            GIFImage(gifName: "Image") // calls makeuiview in gif class
                .scaledToFill()
                .ignoresSafeArea()

            VStack {
                Spacer().frame(height: 150)
                Text("Login")
                    .font(.custom("Rockwell-Bold", size: 35))
                    .bold()
                    .padding(.bottom, 40)
                    .foregroundColor(.white)

                // Adjusted TextField for smaller size
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.vertical, 10) // Adjust vertical padding for height
                    .padding(.horizontal, 15) // Adjust horizontal padding for width
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(width: 300) // Set a fixed width
                    .padding(.bottom, 20)

                // Adjusted SecureField for smaller size
                SecureField("Password", text: $password)
                    .padding(.vertical, 10) // Adjust vertical padding for height
                    .padding(.horizontal, 15) // Adjust horizontal padding for width
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(width: 300) // Set a fixed width
                    .padding(.bottom, 20)

           
            
                    Button(action: signIn) {
                        Text("Login")
                            .foregroundColor(.white)
                            .frame(width: 300)
                            .frame(height: 42)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(color: Color.blue.opacity(0.7), radius: 10, x: 0, y: 0) // Outer glow
                            .shadow(color: Color.blue.opacity(0.5), radius: 20, x: 0, y: 0) // Softer glow
                    }
               
                .padding(.bottom, 20)

                if !errorMessage.isEmpty {
                    Text("provided wrong email or password")
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()

                // Navigation link for Sign Up
                HStack {
                    Text("Not already signed in?")
                        .foregroundColor(.white)
                        .font(.system(size: 17.0))
                        .font(.custom("Rockwell-Bold", size: 35))
                    
                    Button(action: switchToSignupView) { // Action to switch root view
                                            Text("Sign up")
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                                .font(.system(size: 17.0))
                                                .font(.custom("Rockwell-Bold", size: 35))
                                        }
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
    }

    // Function to handle sign-in logic
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                print("Error signing in: \(error.localizedDescription)")
            } else {
                appState.isLoggedIn = true
                print("Successfully signed in")
                switchToMainView()
            }
        }
    }
    
    func switchToMainView() {
        // Find the window and set the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                // Create the main view and inject the appState into it
                let rootView = UIHostingController(rootView: ViewTwo().environmentObject(appState)) // Pass appState to ViewTwo
                
                // Set the root view controller
                window.rootViewController = rootView
                window.makeKeyAndVisible() // Make the window visible
            }
        }
    }
    
    func switchToSignupView() {
            // Find the window and set the root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let window = windowScene.windows.first {
                    let rootView = UIHostingController(rootView: SignupView().environmentObject(appState)) // Pass appState to SignupView
                    window.rootViewController = rootView
                    window.makeKeyAndVisible() // Make the window visible
                }
            }
        }
    }


// Preview Provider
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .previewDevice("iPhone 15") // Optional: Specify a device for preview
    }
}

