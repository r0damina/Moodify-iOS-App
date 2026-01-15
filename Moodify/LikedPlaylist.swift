import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AVFoundation
import AVKit

struct LikedPlaylist: View {
    @State private var likedSongs: [String] = []
    @State private var isLoading: Bool = true
    @StateObject var audioPlayer = AudioPlayer()
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0.0
    @State private var totalDuration: Double = 0.0
    @State private var currentSong: String?
    @State private var name: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var appState: AppState

    var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Image("background3")
                        .resizable()
                        .ignoresSafeArea()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.98)
                    
                    VStack(spacing: 0) {
                        // Header
                        Text("Welcome To " + name + "'s PlayList")
                            .font(.custom("Rockwell-Bold", size: 20))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                            .padding(.top, geometry.safeAreaInsets.top + 10)
                            .padding(.bottom, 10)
                            .frame(width: geometry.size.width)
                            .background(Color.black.opacity(0.3))
                            .shadow(color: Color.blue, radius: 5, x: 0, y: 5)
                        
                        if isLoading {
                            Spacer()
                            ProgressView("Loading your liked songs...")
                                .padding()
                                .foregroundColor(.white)
                            Spacer()
                        } else if likedSongs.isEmpty {
                            Spacer()
                            Text("No liked songs yet!")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        } else {
                            //Songs list with fixed height
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(likedSongs, id: \.self) { song in
                                        Button(action: {
                                            if currentSong != song || !isPlaying {
                                                currentSong = song
                                                audioPlayer.playLocalSong(songName: song)
                                                isPlaying = true
                                                updateCurrentTime()
                                            }
                                        }) {
                                            Text(song)
                                                .font(.body)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 16)
                                                .background(Color.black.opacity(0.6))
                                        }
                                        Divider()
                                            .background(Color.white.opacity(0.2))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            // Add maximum height constraint to leave space for player controls
                            .frame(height: geometry.size.height * 0.6)
                        }
                        
                        Spacer(minLength: 0)
                        
                        // Player controls
                        if let song = currentSong {
                            VStack(spacing: 8) {
                                Text(song)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .padding(.top, 8)
                                
                                Slider(value: $currentTime, in: 0...totalDuration, onEditingChanged: { editing in
                                    if !editing {
                                        audioPlayer.audioPlayer?.currentTime = currentTime
                                    }
                                })
                                .padding(.horizontal)
                                
                                HStack(spacing: 20) {
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
                                            .foregroundColor(.white)
                                    }
                                    
                                    Button(action: {
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = windowScene.windows.first {
                                            window.rootViewController = UIHostingController(rootView: ViewTwo().environmentObject(appState))
                                        }
                                    }) {
                                        Text("Home")
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .foregroundColor(.white)
                                            .background(Color.blue.opacity(0.6))
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        fetchYouTubeVideo(for: song)
                                    }) {
                                        Image(systemName: "play.rectangle")
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 30)
                                            .padding(.vertical, 10)
                                    }
                                    .padding(.trailing)
                                }
                                .padding(.vertical, 10)
                            }
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
                            .background(Color.black.opacity(0.8))
                        }
                    }
                }
            }
            .onAppear {
                fetchLikedSongs()
                fetchNickName()
            }
            .onDisappear {
                audioPlayer.stopSong()
            }
        }

    // Keep all the existing functions exactly the same
    private func fetchLikedSongs() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in.")
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching liked songs: \(error.localizedDescription)")
                isLoading = false
                return
            }

            if let document = document, document.exists {
                if let songs = document.data()?["likedSongs"] as? [String] {
                    self.likedSongs = songs
                } else {
                    print("No liked songs found for the user.")
                }
            } else {
                print("User document does not exist.")
            }
            isLoading = false
        }
    }
    
    private func fetchNickName() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in.")
            isLoading = false
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching NickName: \(error.localizedDescription)")
                isLoading = false
                return
            }

            if let document = document, document.exists {
                if let Nname = document.data()?["NickName"] as? String {
                    DispatchQueue.main.async {
                        self.name = Nname
                    }
                } else {
                    DispatchQueue.main.async {
                        self.name = "No NickName found."
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.name = "User document does not exist."
                }
            }
            isLoading = false
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

#Preview {
    LikedPlaylist()
}
