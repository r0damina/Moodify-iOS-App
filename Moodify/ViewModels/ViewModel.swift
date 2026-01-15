//
//  ViewModel.swift
//  Moodify
//
//  Created by rawand salameh on 24/09/2024.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
private var audioPlayer = AudioPlayer() // Create an instance of AudioPlayer


class ViewModel: ObservableObject {
    
    @Published var happySongs = [String]()
    @Published var sadSongs = [String]()
    @Published var neutralSongs = [String]()
    
    func GetData(forMood mood: String) {
        let db = Firestore.firestore()
        var documentID = ""
        
        // Select document based on mood
        if mood == "Happy" {
            documentID = "CXymZP2voRkwwcGnsrz5"  // Document ID for HappySongs
        } else if mood == "Sad" {
            documentID = "L0iIanSwiKJIzgNzoetq"  // Document ID for SadSongs
        }
  
        
        // Fetch the specific document
        db.collection("PlayLists").document(documentID).getDocument { document, error in
            
            if let error = error {
                print("Error fetching document: \(error)")
                return
            }
            
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    if mood == "Happy" {
                        self.happySongs = document["HappySongs"] as? [String] ?? []
                        print("Happy Songs: \(self.happySongs)")  // Debugging: log happy songs
                    } else if mood == "Sad" {
                        self.sadSongs = document["SadSongs"] as? [String] ?? []
                        print("Sad Songs: \(self.sadSongs)")  // Debugging: log sad songs
                    }
              
                }
            } else {
                print("Document \(documentID) does not exist.")  // Debugging: log if document doesn't exist
            }
        }
    }
    
}
