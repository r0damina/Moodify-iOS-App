import SwiftUI

struct ContentView: View {
     
    @State private var isActive = false//initially false
    @State private var size = 0.8 // Declare size var for animation
    @State private var opacity = 0.5 // Set initial opacity to a higher value
  

    var body: some View {
        ZStack {
            Image("background2")
                .resizable()
                .ignoresSafeArea() // Fills the screen completely
                .aspectRatio(contentMode: .fill) // Center and fill the image
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.98) // background's height is 98% of the screen height // Match the screen size
                
            
            ZStack{
                Image("Logo")//moodify's logo
                    .resizable()
                    .frame(width:650, height: 550)
                    
                Group {
                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: 0, y: -120) // Top of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: 100, y: -90) // Top-right of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: 150, y: 0) // Right of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: 100, y: 90) // Bottom-right of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: 0, y: 120) // Bottom of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: -100, y: 90) // Bottom-left of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: -150, y: 0) // Left of the ellipse

                                Image(systemName: "sparkles")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.color4)
                                    .offset(x: -100, y: -90) // Top-left of the ellipse
                            }
              
                
            }
            
        
            

            if isActive {
                // Show the main content view after the splash screen
                NavigationView {
                    VStack {
                        NavigationLink(destination: SignInView(), isActive: $isActive) {
                            EmptyView() // Activated to next activity when is active is true automatically
                        }
                    }
                }
            } else {
                VStack {
                    
                    Spacer().frame(height: 340) // Add space above the texts
                    
                    
                    
                    //TrebuchetMS ,STIXTwoText_SemiBold,Rockwell-Bold
                    Text("Let Your Mood Choose the Music")
                        .font(.custom("Rockwell-Bold", size: 35))
                        .fontWeight(.heavy)
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .bold()
                        .padding(.top, 350) // Adjust padding if needed
                        .opacity(opacity) // Applying transparent opacity for text
                        .scaleEffect(size)
                        .shadow(color: Color.blue, radius: 5, x: 0, y: 5) //Adding shadow
                        .padding(.horizontal, 30)
                      
                 

                    Spacer() // Pushes everything upwards

                    // Optional: Add another Spacer to control overall vertical position if needed
                }
                
                
                .onAppear {
                     //animation is applied in all view components wherever size and opacity is used
                    withAnimation(.easeIn(duration: 0.9)) {//1.2 is how fast animation is
                        self.size = 0.6
                        self.opacity = 1.0 // Animate to full opacity
                            
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {//after 6 seconds splash screen is removed because my function block will execute
                       
                            self.isActive = true // Change to true
                        
                    }
                 
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

