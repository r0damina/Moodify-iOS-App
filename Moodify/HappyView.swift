import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import AVFoundation
import AVKit

struct HappyView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var audioPlayer = AudioPlayer()
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0.0
    @State private var totalDuration: Double = 0.0
    @ObservedObject var model = ViewModel()
    @State private var currentSong: String?
    @State private var likedSongs: [String: Bool] = [:]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var appState: AppState
    
    var body: some View {
           ZStack {
               // Background gradient
               LinearGradient(gradient: Gradient(colors: [Color.color5, Color.color1, Color.color5]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                   .edgesIgnoringSafeArea(.all)
               
               // Main content
               VStack {
                   ScrollView {
                       VStack(spacing: 0) {
                           ForEach(model.happySongs, id: \.self) { song in
                               HStack {
                                   Button(action: {
                                       if currentSong != song || !isPlaying {
                                           currentSong = song
                                           audioPlayer.playLocalSong(songName: song)
                                           isPlaying = true
                                           updateCurrentTime()
                                       }
                                   }) {
                                       Text(song)
                                           .foregroundColor(.black)
                                           .frame(maxWidth: .infinity, alignment: .leading)
                                   }
                                   
                                   Button(action: {
                                       toggleLikeStatus(for: song)
                                   }) {
                                       Image(systemName: likedSongs[song] == true ? "heart.fill" : "heart")
                                           .resizable()
                                           .aspectRatio(contentMode: .fit)
                                           .frame(width: 30, height: 30)
                                           .foregroundColor(.black)
                                   }
                               }
                               .padding()
                               .background(Color.white.opacity(0.7))
                               .cornerRadius(10)
                               .padding(.horizontal)
                               .padding(.vertical, 4)
                           }
                       }
                   }
                   
                   if let song = currentSong {
                       VStack {
                           HStack {
                               Text("\(song)")
                                   .font(.headline)
                                   .padding(.top)
                               
                               Spacer()
                               
                               Button(action: {
                                   fetchYouTubeVideo(for: song)
                               }) {
                                   Image(systemName: "play.rectangle")
                                       .resizable()
                                       .frame(width: 20, height: 20)
                                       .foregroundColor(.black)
                               }
                               .padding(.trailing)
                           }
                           .padding(.top)

                           Slider(value: $currentTime, in: 0...totalDuration, onEditingChanged: { editing in
                               if !editing {
                                   audioPlayer.audioPlayer?.currentTime = currentTime
                               }
                           })
                           .padding([.leading, .trailing])
                           
                           HStack {
                               Button(action: {
                                   if isPlaying {
                                       audioPlayer.pauseSong()
                                       isPlaying = false
                                   } else {
                                       audioPlayer.audioPlayer?.play()
                                       isPlaying = true
                                   }
                               }) {
                                   Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                       .resizable()
                                       .frame(width: 30, height: 30)
                                       .foregroundColor(.black)
                               }
                               .padding()
                               
                               Button(action: {
                                   if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let window = windowScene.windows.first {
                                       window.rootViewController = UIHostingController(
                                           rootView: LikedPlaylist().environmentObject(appState)
                                       )
                                   }
                               }) {
                                   Text("Go To My Liked PlayList")
                                       .font(.headline)
                                       .padding()
                                       .foregroundColor(.black)
                                       .background(Color.white.opacity(0.7))
                                       .cornerRadius(8)
                               }
                           }
                       }
                       .padding()
                       .background(Color.white.opacity(0.7))
                       .cornerRadius(15)
                       .padding()
                   }
               }
               .navigationTitle("Happy Songs")
           }
           .onAppear {
               loadLikedSongs()
               model.GetData(forMood: "Happy")
           }
           .onChange(of: model.happySongs) { _ in
               loadLikedSongs()
           }
           .onDisappear {
               audioPlayer.stopSong()
           }
           .alert(isPresented: $showingAlert) {
               Alert(title: Text("YouTube Video"),
                     message: Text(alertMessage),
                     dismissButton: .default(Text("OK")))
           }
       }
       
    
    private func toggleLikeStatus(for song: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userDocument = db.collection("users").document(user.uid)
        
        if likedSongs[song] == true {
            likedSongs[song] = false
            userDocument.updateData([
                "likedSongs": FieldValue.arrayRemove([song])
            ]) { error in
                if let error = error {
                    print("Error removing song from likedSongs: \(error.localizedDescription)")
                }
            }
        } else {
            likedSongs[song] = true
            userDocument.updateData([
                "likedSongs": FieldValue.arrayUnion([song])
            ]) { error in
                if let error = error {
                    print("Error adding song to likedSongs: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateCurrentTime() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let player = audioPlayer.audioPlayer, player.isPlaying {
                currentTime = player.currentTime
                totalDuration = player.duration
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func loadLikedSongs() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userDocument = db.collection("users").document(user.uid)
        
        userDocument.getDocument { document, error in
            if let document = document, document.exists {
                if let likedSongsArray = document.data()?["likedSongs"] as? [String] {
                    for song in model.happySongs {
                        likedSongs[song] = likedSongsArray.contains(song)
                    }
                }
            } else {
                print("Error fetching user data: \(error?.localizedDescription ?? "No error description")")
            }
        }
    }
    
    private func fetchYouTubeVideo(for song: String) {
        let youtubeAPIManager = YouTubeAPIManager()
        
        youtubeAPIManager.fetchVideos(query: song) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videos):
                    if let video = videos.first {
                        openYouTubeVideo(videoId: video.id)
                    } else {
                        alertMessage = "No videos found for this song."
                        showingAlert = true
                    }
                case .failure(let error):
                    alertMessage = "Error fetching video: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func openYouTubeVideo(videoId: String) {
        audioPlayer.pauseSong()
        isPlaying = false
        let videoPlayerVC = VideoPlayerViewController()
        videoPlayerVC.videoId = videoId
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(videoPlayerVC, animated: true, completion: nil)
        }
    }
}
