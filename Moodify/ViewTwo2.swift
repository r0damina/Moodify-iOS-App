import SwiftUI
import AVFoundation
import FirebaseAuth

struct ViewTwo: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var shadowOffsetX: CGFloat = 10
    @State private var shadowOffsetY: CGFloat = 10
    @State private var shadowRadius: CGFloat = 30
    @State private var shadowOpacity: Double = 0.8
    @State private var scale: CGFloat = 1.0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            Image("background2")
                .resizable()
                .ignoresSafeArea()
                .aspectRatio(contentMode: .fill)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.97)
            
            VStack {
                Text("Choose Your Option")
                    .font(.custom("Rockwell-Bold", size: 28))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 60)
                    .shadow(color: Color.blue, radius: 5, x: 0, y: 5)
                    .offset(x:5,y:20)
                
                Spacer()
                
                VStack(spacing: 40) {
                    // Capture Your Mood
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: CameraView().environmentObject(appState))
                        }
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 135, height: 150)
                                .foregroundColor(.white)
                                .shadow(color: Color.blue.opacity(shadowOpacity), radius: shadowRadius, x: shadowOffsetX, y: shadowOffsetY)
                            
                            Text("Capture Your Mood")
                                .font(.custom("Rockwell-Bold", size: 12))
                                .fontWeight(.heavy)
                                .foregroundColor(.black)
                                .offset(x:-2,y:-90)
                        }
                        .padding(.vertical, 5)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                    }
                    .padding()
                    
                    // Voice Your Mood
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: TestView().environmentObject(appState))
                        }
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 135, height: 150)
                                .foregroundColor(.white)
                                .shadow(color: Color.blue.opacity(shadowOpacity), radius: shadowRadius, x: shadowOffsetX, y: shadowOffsetY)
                            
                            Text("Voice Your Mood")
                                .font(.custom("Rockwell-Bold", size: 12))
                                .fontWeight(.heavy)
                                .foregroundColor(.black)
                                .offset(x:-2,y:-90)
                        }
                        .padding(.vertical, 5)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                    }
                    .padding()
                    
                    // Type Your Mood
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: PromtText().environmentObject(appState))
                        }
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 135, height: 150)
                                .foregroundColor(.white)
                                .shadow(color: Color.blue.opacity(shadowOpacity), radius: shadowRadius, x: shadowOffsetX, y: shadowOffsetY)
                            
                            Text("Type Your Mood")
                                .font(.custom("Rockwell-Bold", size: 12))
                                .fontWeight(.heavy)
                                .foregroundColor(.black)
                                .offset(x:-2,y:-90)
                        }
                        .padding(.vertical, 5)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                    }
                    .padding()
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Bottom Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: LikedPlaylist().environmentObject(appState))
                        }
                    }) {
                        Text("Go To Playlist")
                            .font(.custom("Rockwell-Bold", size: 12))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 40)
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(color: Color.white, radius: 10, x: 0, y: 5)
                    .offset(x: -20, y: -60)
                    
                    Button(action: {
                        signOut()
                        appState.isLoggedIn = false // Ensure app state is reset
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(
                                rootView: SignInView().environmentObject(appState)
                            )
                            window.makeKeyAndVisible()
                        }
                    }) {
                        Text("Log Out")
                            .font(.custom("Rockwell-Bold", size: 12))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 40)
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(color: Color.white, radius: 10, x: 0, y: 5)
                    .offset(x: 20, y: -60)
                }
                .padding(.bottom, 30)
            }
        }
    }
    private func signOut() {
        do {
            try Auth.auth().signOut()
            appState.isLoggedIn = false
            print("Successfully logged out")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }

}

#Preview {
    ViewTwo()
}
