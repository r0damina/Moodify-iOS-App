import SwiftUI
import AVFoundation
import CoreML
import AudioKit   // "swift version of librosa"
import Accelerate
import Foundation

struct VoiceView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                audioRecorder.toggleRecording()
            }) {
                Text(audioRecorder.isRecording ? "Stop Recording" : "Record Voice")
                    .foregroundColor(.white)
                    .frame(width: 300, height: 42)
                    .background(audioRecorder.isRecording ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: {
                audioRecorder.playRecording()
            }) {
                Text("Play Recording")
                    .foregroundColor(.white)
                    .frame(width: 300, height: 42)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            Button(action: {
                audioRecorder.predictMood()
            }) {
                Text("Predict Mood")
                    .foregroundColor(.white)
                    .frame(width: 300, height: 42)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let audioSession = AVAudioSession.sharedInstance()
    
    /// M4A file location
    private let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")
    /// WAV file location
    private var wavURL: URL?
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            print("Recording started. File saved at: \(audioFilename)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        print("Recording stopped. File saved at: \(audioFilename)")
        convertToWav()
    }
    
    private func convertToWav() {
        let m4aURL = audioFilename
        wavURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")
        
        print("Input File: \(m4aURL.path)")
        print("Output File: \(wavURL?.path ?? "unknown")")
        
        guard FileManager.default.fileExists(atPath: m4aURL.path) else {
            print("Input file does not exist.")
            return
        }
        
        do {
            let inputFile = try AVAudioFile(forReading: m4aURL)
            
            /// We'll convert to 16-bit, 16kHz, mono WAV
            let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                             sampleRate: 16000,
                                             channels: 1,
                                             interleaved: true)!
            let outputFile = try AVAudioFile(forWriting: wavURL!, settings: outputFormat.settings)
            
            let frameCapacity = AVAudioFrameCount(inputFile.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: inputFile.processingFormat, frameCapacity: frameCapacity) else {
                print("Failed to create PCM buffer.")
                return
            }
            
            try inputFile.read(into: buffer)
            try outputFile.write(from: buffer)
            
            print("Conversion successful: \(wavURL!.path)")
        } catch {
            print("Error during conversion: \(error.localizedDescription)")
        }
    }
    
    func playRecording() {
        let wavURL = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")
        
        guard FileManager.default.fileExists(atPath: wavURL.path) else {
            print("No WAV recording found to play.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: wavURL)
            audioPlayer?.play()
            print("Playing WAV recorded audio.")
        } catch {
            print("Failed to play WAV audio: \(error.localizedDescription)")
        }
    }
    
    func predictMood() {
        guard let wavFile = wavURL, FileManager.default.fileExists(atPath: wavFile.path) else {
            print("Error: WAV file not found for prediction.")
            return
        }
        
        do {
            // Here we do feature extraction from the WAV file
            let features = try extractAudioFeatures(from: wavFile)
            
            // Expect a total of 128 (Mel) + 40 (MFCC) + 12 (Chroma) = 180
            guard features.count == 180 else {
                print("Error: Feature count != 180. Got \(features.count).")
                return
            }
            
            // Prepare MLMultiArray for the model
            let input = try MLMultiArray(shape: [1, NSNumber(value: features.count)], dataType: .double)
            for (index, feature) in features.enumerated() {
                input[[0, index] as [NSNumber]] = NSNumber(value: feature)
            }
            
            // Load your Core ML model
            guard let model = try? MLSpeech_SVC(configuration: MLModelConfiguration()) else {
                print("Failed to load model.")
                return
            }
            
            // Predict
            let prediction = try model.prediction(input: input)
            print("Predicted mood: \(prediction.classLabel)")
        } catch {
            print("Error during prediction: \(error.localizedDescription)")
        }
    }
    
    // MARK: Offline Feature Extraction
    
    /// Reads the WAV file, pulls a single 1024-sample frame (or more),
    /// and computes 128 Mel, 40 MFCC, 12 Chroma => total 180 features.
    private func extractAudioFeatures(from fileURL: URL) throws -> [Float] {
        // 1) Open the WAV file
        let audioFile = try AVAudioFile(forReading: fileURL)
        let processingFormat = audioFile.processingFormat
        
        // We'll read exactly 1024 frames from the start for demonstration.
        // (You can read more frames and average or do some aggregation if needed.)
        let frameCount: AVAudioFrameCount = 1024
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: frameCount) else {
            print("Error: couldn't create PCM buffer")
            return []
        }
        
        try audioFile.read(into: buffer, frameCount: frameCount)
        
        // If the WAV is shorter than 1024 frames, buffer.frameLength might be < 1024
        let actualFrames = Int(buffer.frameLength)
        if actualFrames < 1024 {
            print("Warning: file shorter than 1024 samples, got only \(actualFrames) frames")
        }
        
        // 2) Convert PCM buffer to [Float] (mono)
        //    We assume 1 channel (16kHz, 16-bit, mono), so:
        guard let channelData = buffer.floatChannelData?[0] else {
            print("No channel data.")
            return []
        }
        
        // We'll only process the first `actualFrames` samples.
        // If you want to zero-pad up to 1024, you can do so.
        let sampleArray = Array(UnsafeBufferPointer(start: channelData, count: actualFrames))
        
        // If needed, zero-pad to length 1024:
        var paddedSamples = sampleArray
        if paddedSamples.count < 1024 {
            paddedSamples += [Float](repeating: 0, count: 1024 - paddedSamples.count)
        }
        
        // 3) Compute FFT of these 1024 samples => power spectrum
        //    We'll do a basic approach with Accelerate. Or you can reuse code from your class.
        
        let fftSize = 1024
        let log2n = vDSP_Length(log2f(Float(fftSize)))
        
        // Prepare buffers for Accelerate real FFT
        var realp = [Float](repeating: 0.0, count: fftSize/2)
        var imagp = [Float](repeating: 0.0, count: fftSize/2)
        
        // For a Hanning window, for instance:
        var window = [Float](repeating: 0.0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), 0)
        
        // Multiply samples by window in-place
        var windowedSamples = [Float](repeating: 0.0, count: fftSize)
        vDSP_vmul(paddedSamples, 1, window, 1, &windowedSamples, 1, vDSP_Length(fftSize))
        
        // Create split complex struct
        var splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        // Forward real FFT
        windowedSamples.withUnsafeMutableBufferPointer { ptr in
            ptr.withMemoryRebound(to: DSPComplex.self) { typeConvertedTransferBuffer in
                let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
                vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                vDSP_destroy_fftsetup(fftSetup!)
            }
        }
        
        // Since it's a real FFT, we need to scale by 1/2 for amplitude
        var scale: Float = 1.0 / 2.0
        vDSP_vsmul(realp, 1, &scale, &realp, 1, vDSP_Length(fftSize/2))
        vDSP_vsmul(imagp, 1, &scale, &imagp, 1, vDSP_Length(fftSize/2))
        
        // Convert to magnitude^2 => power spectrum
        var powerSpectrum = [Float](repeating: 0.0, count: fftSize/2)
        vDSP_zvmags(&splitComplex,
                    1,
                    &powerSpectrum,
                    1,
                    vDSP_Length(fftSize/2))
        
        // 4) Compute 128 Mel + 40 MFCC + 12 Chroma from powerSpectrum
        //    We can do so using the same math from your AudioFeatureExtractor code
        //    but in a single offline function here.
        
        let sampleRate: Float = Float(audioFile.fileFormat.sampleRate)
        let (mel128, mfcc40) = computeMelAndMFCC(powerSpectrum: powerSpectrum,
                                                 sampleRate: sampleRate,
                                                 fftSize: fftSize)
        
        let chroma12 = computeChroma(powerSpectrum: powerSpectrum,
                                     sampleRate: sampleRate,
                                     fftSize: fftSize)
        
        // Combine [mel128 + mfcc40 + chroma12] => 180 features
        let allFeatures: [Float] = mel128 + mfcc40 + chroma12
        return allFeatures
    }
}

// MARK: - Offline DSP for Mel (128), MFCC (40), Chroma (12)

extension AudioRecorder {
    /// Returns (mel128, mfcc40) from a given powerSpectrum.
    private func computeMelAndMFCC(powerSpectrum: [Float],
                                   sampleRate: Float,
                                   fftSize: Int) -> ([Float], [Float]) {
        // 1) Create or cache Mel filter banks for 128 filters
        let numMelFilters = 128
        let melFilters = createMelFilterBanks(
            numFilters: numMelFilters,
            fftSize:    fftSize,
            sampleRate: sampleRate,
            minFreq:    0.0,
            maxFreq:    sampleRate / 2.0
        )
        
        // 2) Apply mel filters => [128] energies
        var melEnergies = [Float](repeating: 0.0, count: numMelFilters)
        for m in 0..<numMelFilters {
            var sum: Float = 0
            vDSP_dotpr(powerSpectrum, 1,
                       melFilters[m], 1,
                       &sum,
                       vDSP_Length(powerSpectrum.count))
            melEnergies[m] = sum
        }
        
        // 3) log-mel
        let logMel = melEnergies.map { logf($0 + 1e-8) }
        
        // 4) DCT => get 40 MFCC
        let mfcc40 = dct(logMel, outputSize: 40)
        
        return (melEnergies, mfcc40)
    }
    
    /// Creates 128 triangular mel filters
    private func createMelFilterBanks(numFilters: Int,
                                      fftSize: Int,
                                      sampleRate: Float,
                                      minFreq: Float,
                                      maxFreq: Float) -> [[Float]] {
        // Convert freq <-> mel
        func hzToMel(_ hz: Float) -> Float {
            return 2595.0 * log10(1 + hz / 700.0)
        }
        func melToHz(_ mel: Float) -> Float {
            return 700.0 * (pow(10, mel / 2595.0) - 1)
        }
        
        let minMel = hzToMel(minFreq)
        let maxMel = hzToMel(maxFreq)
        
        // We create numFilters+2 breakpoints in mel scale
        let melPoints = (0..<(numFilters+2)).map { i -> Float in
            let fraction = Float(i) / Float(numFilters+1)
            return minMel + fraction * (maxMel - minMel)
        }
        
        let hzPoints = melPoints.map { melToHz($0) }
        
        // Convert Hz to FFT bin indices
        let binPoints = hzPoints.map { freq -> Int in
            let bin = Int((Float(fftSize) * freq / sampleRate).rounded())
            return min(bin, fftSize/2)
        }
        
        // Initialize
        var filterBank = [[Float]](
            repeating: [Float](repeating: 0.0, count: fftSize/2),
            count: numFilters
        )
        
        for m in 1...numFilters {
            let start = binPoints[m-1]
            let peak  = binPoints[m]
            let end   = binPoints[m+1]
            
            for k in start..<peak {
                if peak > start {
                    filterBank[m-1][k] = (Float(k) - Float(start)) / Float(peak - start)
                }
            }
            for k in peak..<end {
                if end > peak {
                    filterBank[m-1][k] = (Float(end) - Float(k)) / Float(end - peak)
                }
            }
        }
        
        return filterBank
    }
    
    /// DCT-II of logMel, keeping only first `outputSize` coefficients
    private func dct(_ logMel: [Float], outputSize: Int) -> [Float] {
        let count = logMel.count  // e.g. 128
        var transformed = [Float](repeating: 0.0, count: count)
        
        guard let dctSetup = vDSP.DCT(count: count, transformType: .II) else {
            return Array(repeating: 0.0, count: outputSize)
        }
        
        dctSetup.transform(logMel, result: &transformed)
        
        if count > outputSize {
            return Array(transformed[0..<outputSize])
        } else {
            return transformed
        }
    }
    
    /// Compute 12-dim Chroma from powerSpectrum
    private func computeChroma(powerSpectrum: [Float],
                               sampleRate: Float,
                               fftSize: Int) -> [Float] {
        let numBins = 12
        var chroma = [Float](repeating: 0.0, count: numBins)
        
        let binCount = powerSpectrum.count  // typically fftSize/2
        let freqResolution = sampleRate / Float(fftSize)
        
        // For each bin k => frequency = k * freqResolution
        for k in 1..<binCount {
            let freq = Float(k) * freqResolution
            // MIDI formula: 69 + 12*log2(freq/440)
            let midiFloat = 69.0 + 12.0 * log2f(freq / 440.0)
            
            // Round to nearest pitch, mod 12 => pitch class
            let pitchClass = Int(round(midiFloat)) % numBins
            chroma[pitchClass] += powerSpectrum[k]
        }
        
        // Optional normalization
        let sumEnergy = chroma.reduce(0, +)
        if sumEnergy > 0 {
            for i in 0..<numBins {
                chroma[i] /= sumEnergy
            }
        }
        
        return chroma
    }
}

// MARK: AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed.")
        }
    }
}

// SwiftUI preview
#Preview {
    VoiceView()
}
