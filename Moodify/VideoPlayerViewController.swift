import UIKit
import WebKit

class VideoPlayerViewController: UIViewController {
    var videoId: String!
    private var webView: WKWebView!
    
    override func loadView() {
        // Configure WKWebView with required settings
        let configuration = WKWebViewConfiguration()

        //zero means fill entire view 
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoId = videoId else { return }
      
        
        let embedURL = "https://www.youtube.com/watch?v=\(videoId)"
        
        
 
        
        print(videoId)
        
        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

// Add WKNavigationDelegate to handle errors
extension VideoPlayerViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed to load video: \(error.localizedDescription)")
        // Show error to user
        let alert = UIAlertController(
            title: "Video Unavailable",
            message: "This video cannot be played. It might be region-restricted or removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Video loaded successfully")
    }
}
