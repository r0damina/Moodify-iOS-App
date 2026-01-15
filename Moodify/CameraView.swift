import SwiftUI
import AVFoundation
import UIKit
import CoreML

struct CameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var image: UIImage? = nil
    @State private var predictionResult: String = ""
    @State private var isShowingCamera = true
    @ObservedObject private var modelManager = ModelManager.shared
    @State private var navigationWorkItem: DispatchWorkItem? //holds delayed navigation
    @State private var shouldNavigate = false //controls when to navigate
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea(.all, edges: .all)
                //incase image captured
                VStack(spacing: 20) {
                    Spacer()
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: geometry.size.height * 0.7)
                        
                        Text(predictionResult)
                            .foregroundColor(.white)
                            .padding()
                        
                        Button("Take Another Photo") {
                            // Cancel the pending navigation task
                               navigationWorkItem?.cancel()
                               navigationWorkItem = nil
                               // Disable navigation
                               shouldNavigate = false
                            self.isShowingCamera = true
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraInterfaceView(image: $image,
                              onImageCaptured: { capturedImage in
                if let resizedImage = resizeImage(image: capturedImage, targetSize: CGSize(width: 224, height: 224)) {
                    performPrediction(with: resizedImage)
                }
            }, onCancel: {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {//grabs the active window(camera view) from the scene
                    window.rootViewController = UIHostingController(rootView: ViewTwo().environmentObject(appState))//root view container decides what view is being shown in the window container, put the root view as view two
                }
            })
            .edgesIgnoringSafeArea(.all)
        }
    }
    //uses image context to redraw image with desired size 224 by 224
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    func imageToMultiArray(_ image: UIImage) -> MLMultiArray? {
        guard let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 224, height: 224)),
              let cgImage = resizedImage.cgImage else { return nil }

        let width = 224
        let height = 224
        let pixels = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))//cg image is drawn

        guard let multiArray = try? MLMultiArray(shape: [1, 3, NSNumber(value: height), NSNumber(value: width)], dataType: .float32) else {
            print("Failed to create MLMultiArray")
            return nil
        }

        let redPointer = multiArray.dataPointer.assumingMemoryBound(to: Float32.self)
        let greenPointer = redPointer.advanced(by: width * height)
        let bluePointer = greenPointer.advanced(by: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                //normalized values
                let red = Float(pixels[pixelIndex]) / 255.0
                let green = Float(pixels[pixelIndex + 1]) / 255.0
                let blue = Float(pixels[pixelIndex + 2]) / 255.0

                let index = y * width + x
                redPointer[index] = red
                greenPointer[index] = green
                bluePointer[index] = blue
            }
        }

        pixels.deallocate()
        return multiArray
    }

   
    func performPrediction(with image: UIImage) {
        guard let model = modelManager.model,
              let inputArray = imageToMultiArray(image) else {
            return
        }

        do {
            let input = EmotionDetectionModelInput(x_1: inputArray)
            let prediction = try model.prediction(input: input)
            let output = prediction.linear_0
            //enter the multiarray memory values then extract the probabilities in an array after it is 7 classes of probabilities
            let probabilities = Array(UnsafeBufferPointer(start: output.dataPointer.assumingMemoryBound(to: Float32.self), count: output.count))
            //enumirates uinside array to find the max probability and returns its index if no prediction is found the default gives index 0
            let dominantEmotionIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0

            let FER_2013_EMO_DICT: [Int: String] = [
                0: "Angry",
                1: "Disgust",
                2: "Fear",
                3: "Happy",
                4: "Sad",
                5: "Surprise",
                6: "Neutral"
            ]

            let dominantEmotion = FER_2013_EMO_DICT[dominantEmotionIndex] ?? "Unknown"
            predictionResult = "Predicted Emotion: \(dominantEmotion)"
            
            // Cancel any previous navigation pending
            navigationWorkItem?.cancel()
            
            // Set navigation flag before creating work item
            shouldNavigate = true
            
            // Create a new work item for navigation
            let workItem = DispatchWorkItem {
                if shouldNavigate {
                    DispatchQueue.main.async {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            switch dominantEmotion {
                            case "Happy":
                                window.rootViewController = UIHostingController(rootView: HappyView().environmentObject(appState))
                            case "Sad":
                                window.rootViewController = UIHostingController(rootView: SadView().environmentObject(appState))
                            default:
                                window.rootViewController = UIHostingController(rootView: HappyView().environmentObject(appState))
                            }
                        }
                    }
                }
            }
            
            // Store the work item
            navigationWorkItem = workItem
            
            // Schedule the navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
            
        } catch {
            print("Error during prediction: \(error.localizedDescription)")
        }
    }
}
//camerainterfaceview wraps arund UIImagePickerController that is created via UIViewControllerRepresentable protocol
struct CameraInterfaceView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void
    //delegate calls image capture or cancel
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraInterfaceView

        init(parent: CameraInterfaceView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageCaptured(uiImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
            parent.onCancel()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#Preview {
    CameraView()
}
