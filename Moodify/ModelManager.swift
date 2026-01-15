//
//  ModelManager.swift
//  Moodify
//
//  Created by rawand salameh on 31/12/2024.
//

import Foundation
import CoreML

class ModelManager:ObservableObject{
    
    static let shared = ModelManager() // Singleton instance
    @Published var model: EmotionDetectionModel?
    
    init(){
        loadModel()// anything inside an init function executes automatically when creating an instance of the class
    }
    
    // Function to load the Core ML model
    func loadModel() {
        do {
            model = try EmotionDetectionModel(configuration: MLModelConfiguration())
            print("Model loaded successfully")
        } catch {
            print("Failed to load model: \(error.localizedDescription)")
        }
    }
    
    
}
