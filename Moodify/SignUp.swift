import SwiftUI
import FirebaseAuth
import FirebaseFirestore//because i need to add the new user to users collection

struct SignupView: View {
    // Variables to store the email, password, and any error message
    @State private var email = ""
    @State private var password = ""
    @State private var password2 = ""
    @State private var Nickname = ""
    @State private var errorMessage = ""
    @State private var isSignupSuccessful = false // New state to track signup success
    @EnvironmentObject var appState: AppState
    
    var body: some View {
            ZStack {
                GIFImage(gifName: "Image")
                    .scaledToFill()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack {
                        Spacer().frame(height: 150)
                        
                        Text("Sign Up")
                            .font(.custom("Rockwell-Bold", size: 35))
                            .bold()
                            .padding(.bottom, 40)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 20) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            SecureField("Re-enter password", text: $password2)
                                .textFieldStyle(CustomTextFieldStyle())
                            
                            TextField("Give yourself a NickName", text: $Nickname)
                                .autocapitalization(.none)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        .frame(maxWidth: 300)
                        
                        Button(action: signUp) {
                            Text("Sign Up")
                                .foregroundColor(.white)
                                .frame(width: 300, height: 42)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(color: Color.blue.opacity(0.7), radius: 10)
                                .shadow(color: Color.blue.opacity(0.5), radius: 20)
                        }
                        .padding(.top, 20)
                        
                        Button(action: switchToSignInView) {
                            Text("Go Back To Sign In")
                                .font(.system(size: 17, weight: .bold))
                                .padding()
                                .foregroundColor(.blue)
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        if isSignupSuccessful {
                            Text("Signup Successful! Welcome!")
                                .foregroundColor(.green)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        
        // Custom TextFieldStyle for consistent styling
        struct CustomTextFieldStyle: TextFieldStyle {
            func _body(configuration: TextField<Self._Label>) -> some View {
                configuration
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
        }
    
    // Function to handle signup logic
    func signUp() {
        // Check for empty fields
        guard !email.isEmpty, !password.isEmpty , !password2.isEmpty else {
            errorMessage = "Please fill all boxes."
            return
        }
        
        //check atching passwords
        guard password == password2 else {
            errorMessage = "Passwords do not match."
            return
        }
        
        // Check password length
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters long."
            return
        }
        
        // Check password length
        guard !Nickname.isEmpty else {
            errorMessage = "please provide a Nickname."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = result?.user {
                // Success! Now store the email in Firestore
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "email": email,
                    "createdAt": Date(),
                    "likedSongs": [],
                    "NickName": Nickname
                    
                    
                ]) { error in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    } else {
                        
                        // Update state to indicate successful signup
                        isSignupSuccessful = true
                        errorMessage = "" // Clear any previous error messages
                        
                    }
                }
            }
        }
    }
    
    func switchToSignInView() {
            // Find the window and set the root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let window = windowScene.windows.first {
                    let rootView = UIHostingController(rootView: SignInView().environmentObject(appState)) // Pass appState to SignInView
                    window.rootViewController = rootView
                    window.makeKeyAndVisible() // Make the window visible
                }
            }
        }
    }

    // Preview Provider
    struct SignUpView_Previews: PreviewProvider {
        static var previews: some View {
            SignupView()
                .previewDevice("iPhone 15") // Optional: Specify a device for preview
        }
    }

