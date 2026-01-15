//
//  Gif.swift
//  Moodify
//
//  Created by rawand salameh on 05/11/2024.
//

import SwiftUI
import FLAnimatedImage //added to pod file, this is a UIkit component

struct GIFImage: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> FLAnimatedImageView {
        let imageView = FLAnimatedImageView()
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            let animatedImage = FLAnimatedImage(animatedGIFData: data)//the object that will carry teh provided gif
            imageView.animatedImage = animatedImage //set the intance of the class with the animatedImage that has teh gif
        }
        return imageView
    }

    func updateUIView(_ uiView: FLAnimatedImageView, context: Context) {
        // No need to update the view
    }
}




