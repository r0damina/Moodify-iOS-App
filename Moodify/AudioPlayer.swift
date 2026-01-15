//
//  AudioPlayer.swift
//  Moodify
//
//  Created by rawand salameh on 07/10/2024.
//

import Foundation
import AVFoundation
// observable object means shared object
class AudioPlayer: ObservableObject {
    var audioPlayer: AVAudioPlayer?

    // Play a local song from the app bundle
    func playLocalSong(songName: String) {
        // Look for the song in the app bundle by its name
        if let filePath = Bundle.main.path(forResource: songName, ofType: "mp3") {
            let fileURL = URL(fileURLWithPath: filePath)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer?.play()
                print("Playing local song: \(songName)")
            } catch {
                print("Error playing local song: \(error.localizedDescription)")
            }
        } else {
            print("Local song not found: \(songName)")
        }
    }
    
    // Pause the currently playing song
    func pauseSong() {
        audioPlayer?.pause()
    }

    // Stop the currently playing song
    func stopSong() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // Check if a song is currently playing
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
}
