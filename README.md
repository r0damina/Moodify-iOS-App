**Moodify-iOS-App**
**SwiftUI project for mood-based music recommendations**

Overview
Moodify is an iOS application that provides personalized music recommendations based on your current mood. The app uses advanced machine learning models for face recognition and voice analysis to detect emotions and suggest appropriate music.

**Features :**

🎭 Face Recognition: Detects 7 different emotions from facial expressions
🎤 Voice Analysis: Analyzes voice patterns to determine mood (Sad/Happy)
🎵 Music Recommendations: Suggests songs based on detected emotions
📱 SwiftUI Interface: Modern, futuristic and native iOS user experience

**Requirements :**

macOS with Xcode installed
iOS development environment
CocoaPods installed
Minimum iOS deployment target: [Check Podfile for specific version]

Installation & Setup :
**1. Clone the Repository**
bashgit clone https://github.com/[your-username]/Moodify-iOS-App.git
cd Moodify-iOS-App

**2. Download Required ML Models**
IMPORTANT: The machine learning models are not included in this repository due to their large file sizes. You must download them separately before running the project.
Download the following models from Google Drive:

MLSpeech_SVC.mlmodel
EmotionDetectionModel.mlpackage

Google Drive Link: [https://drive.google.com/drive/u/0/folders/1lJCoOPHuOuwNsD-fK2-Rfbw8WA7giK9b]

**3. Install Models**
After downloading the models, you need to place them in the correct location:

Navigate to the Moodify folder in your project directory
Create a new folder called model (if it doesn't exist)
Copy both downloaded model files into the Moodify/model/ directory

Your directory structure should look like this:
Moodify-iOS-App/
├── Moodify/
│   ├── model/
│   │   ├── [face-recognition-model-file]
│   │   └── [voice-recognition-model-file]
│   └── [other project files]
├── Moodify.xcodeproj
├── Moodify.xcworkspace
└── Podfile

**4. Install CocoaPods Dependencies**
pod install

**6. Open the Project**
IMPORTANT: Always open the project using the .xcworkspace file, not the .xcodeproj file:
open Moodify.xcworkspace

**7. Build and Run**

Select your target device or simulator in Xcode
Press Cmd + R or click the Run button
Wait for the build to complete

**About Newstyle.py**
The Newstyle.py file is included for reference purposes. It demonstrates:

How the voice recognition model was trained on multiple custom datasets
Training methodology and data processing

This file is not required to run the iOS application but provides insight into the model development process.
