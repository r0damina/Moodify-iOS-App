import SwiftUI
import CoreML
import Foundation
import UIKit

struct TestView: View {
    @StateObject private var predictor = FeaturePredictor()
    @State private var Clickedbutton: Double = 0.0
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack{
            GIFImage(gifName: "Image")
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if predictor.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
                
                Button(action: {
                    Clickedbutton = 0.0
                    predictor.predictFromFeatures(buttonValue: Clickedbutton)
                }) {
                    Text("load happy audio features and predict")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 100)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .offset(x:0,y:-50)
                }
                .disabled(predictor.isLoading)
                .padding()
                
                Button(action: {
                    Clickedbutton = 1.0
                    predictor.predictFromFeatures(buttonValue: Clickedbutton)
                }) {
                    Text("load sad audio features and predict")
                        .foregroundColor(.white)
                        .frame(width: 200, height: 100)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(predictor.isLoading)
                
                if let prediction = predictor.prediction {
                    Text("Predicted Mood: \(prediction)")
                        .font(.title2)
                        .padding()
                }
                
                if let error = predictor.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .onChange(of: predictor.prediction) { prediction in
                handlePrediction(prediction)
            }
        }
    }

    private func handlePrediction(_ prediction: String?) {
        guard let prediction = prediction else {
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            let destinationView: some View = {
                if prediction.lowercased() == "happy" {
                    print("you're feeling happy")
                    return AnyView(HappyView().environmentObject(appState))
                } else if prediction.lowercased() == "sad" {
                    print("you're feeling sad")
                    return AnyView(SadView().environmentObject(appState))
                } else {
                    print("Unknown prediction: \(prediction)")
                    return AnyView(TestView().environmentObject(appState))
                }
            }()
            
            window.rootViewController = UIHostingController(rootView: destinationView)
        }
    }
}

class FeaturePredictor: ObservableObject {
    @Published var isLoading = false
    @Published var prediction: String?
    @Published var error: String?

    private var model: MLSpeech_SVC?

    init() {
        do {
            self.model = try MLSpeech_SVC(configuration: MLModelConfiguration())
        } catch {
            self.error = "Failed to load model: \(error.localizedDescription)"
        }
    }

    private func loadFeatures(from fileName: String) throws -> [Double] {
        // Get the file URL for the text file
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "txt") else {
            throw PredictorError.fileNotFound
        }
        
        // Load the content of the text file
        let content = try String(contentsOf: fileURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines) // Remove any whitespace
        
        // Split by commas and convert to doubles
        let features = content
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        
        print("Loaded \(features.count) features") // Debug print
        print("First few features: \(Array(features.prefix(5)))") // Debug print
        
        return features
    }

    @MainActor
    func predictFromFeatures(buttonValue: Double) {
        isLoading = true
        error = nil
        prediction = nil

        Task {
            do {
                // Decide which file to load
                let features: [Double]
                if buttonValue == 0.0 {
                    // happy
                    features = try loadFeatures(from: "Rawand5Happy_c_swift")
                } else {
                    // sad
                    features = try loadFeatures(from: "Rawand3Sad_c_swift")
                }

                guard features.count == 180 else {
                    throw PredictorError.invalidFeatureCount(features.count)
                }

                let input = try MLMultiArray(shape: [1, 180], dataType: .double)
                for (index, feature) in features.enumerated() {
                    input[[0, NSNumber(value: index)] as [NSNumber]] = NSNumber(value: feature)
                }

                guard let model = self.model else {
                    throw PredictorError.modelNotLoaded
                }

                let prediction = try model.prediction(input: input)

                await MainActor.run {
                    self.prediction = prediction.classLabel
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    switch error {
                    case PredictorError.fileNotFound:
                        self.error = "Feature file not found"
                    case PredictorError.invalidFeatureCount(let count):
                        self.error = "Invalid feature count: got \(count), expected 180"
                    case PredictorError.modelNotLoaded:
                        self.error = "Model not loaded"
                    default:
                        self.error = "Prediction error: \(error.localizedDescription)"
                    }
                    self.isLoading = false
                }
            }
        }
    }
}

enum PredictorError: Error {
    case fileNotFound
    case invalidFeatureCount(Int)
    case modelNotLoaded
}

#Preview {
    TestView()
}

