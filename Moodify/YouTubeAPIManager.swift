import Foundation

class YouTubeAPIManager {
    let apiKey = "AIzaSyCHswwz2TT3DBLNKoMEM9mM8t47Q3gMmoU" //my api key to connect with youtube v3
    let baseUrl = "https://www.googleapis.com/youtube/v3/search" //youtube v3 endpoint
    
    func fetchVideos(query: String, completion: @escaping (Result<[YouTubeVideo], Error>) -> Void) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "" //the song selected
        let urlString = "\(baseUrl)?part=snippet&q=\(queryEncoded)&type=video&videoEmbeddable=true&videoSyndicated=true&regionCode=JO&safeSearch=none&relevanceLanguage=ar&order=relevance&key=\(apiKey)"
        //here we are preparing the URLstring to send as a request to youtube API, with my query song name , i only gave it the snippet part as in title, and specifies that it is video and other conditions
        
        //converting the url string into an actual url
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: nil)))
            return
        }
        
        print("Making request to: \(urlString)") // Debug print
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in //http request using URLsession using the created url
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
                return
            }
            
            // Debug print the JSON response with the expected youtube API response for a video
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received JSON: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(YouTubeAPIResponse.self, from: data)
                let videos = apiResponse.items.map { item in
                    YouTubeVideo(
                        id: item.id.videoId,
                        title: item.snippet.title,
                        isEmbeddable: true
                    )
                }
                //error handler
                completion(.success(videos))
            } catch {
                print("Decoding error: \(error)") // Debug print
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

// Response models matching exact YouTube API structure
struct YouTubeAPIResponse: Codable {
    let kind: String
    let etag: String
    let nextPageToken: String?
    let regionCode: String?
    let pageInfo: PageInfo
    let items: [YouTubeVideoItem]
}

struct PageInfo: Codable {
    let totalResults: Int
    let resultsPerPage: Int
}

//indivisual video info
struct YouTubeVideoItem: Codable {
    let kind: String
    let etag: String
    let id: VideoId
    let snippet: Snippet
}

struct VideoId: Codable {
    let kind: String
    let videoId: String
}
//video metadeta
struct Snippet: Codable {
    let publishedAt: String
    let channelId: String
    let title: String
    let description: String
    let thumbnails: Thumbnails
    let channelTitle: String
    let liveBroadcastContent: String
}

struct Thumbnails: Codable {
    let `default`: ThumbnailDetails
    let medium: ThumbnailDetails
    let high: ThumbnailDetails
    
    enum CodingKeys: String, CodingKey {
        case `default` = "default"
        case medium
        case high
    }
}

struct ThumbnailDetails: Codable {
    let url: String
    let width: Int
    let height: Int
}

struct YouTubeVideo {
    let id: String
    let title: String
    let isEmbeddable: Bool
    
    // Add a function to get the watch URL instead of embed URL
        func getWatchURL() -> URL? {
            return URL(string: "https://www.youtube.com/watch?v=\(id)")
        }
        
        // Or if you need embed URL
        func getEmbedURL() -> URL? {
            return URL(string: "https://www.youtube.com/embed/\(id)")
        }
}
