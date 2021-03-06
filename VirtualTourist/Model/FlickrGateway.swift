

import UIKit

class FlickrGateway {
    static let scheme = "https"
    static let host = "www.flickr.com"
    static let path = "/services/rest"

    static let apiKeyParam = "api_key"
    static let apiKey = "460447e487f124765101a8c0b859587b"
    static let methodParam = "method"
    static let latitudeParam = "lat"
    static let longitudeParam = "lon"
    static let radiusParam = "radius"
    static let perPageParam = "per_page"
    static let pageParam = "page"
    static let formatParam = "format"
    static let noJsonCallBackParam = "nojsoncallback"

    static let searchMethodValue = "flickr.photos.search"
    static let radiusValue = 10
    static let perPageValue = 25

    static let getInfoMethodValue = "flickr.photos.getInfo"
    static let photoIdParam = "photo_id"
    static let photoSizeParam = "q" // Large Square

    static let formatValue = "json"
    static let noJsonCallBackValue = 1



    private var totalPages = 0
    private var randomPage: Int {
        // For some reason Flickr API always returns the first page when the requested page is big,
        // even if it is still smaller than returned total pages, so the randomization is lost.
        // So I've opted to use a fixed value to limit the requested page and ensure the randomization
        // Similar issue: https://stackoverflow.com/questions/44991024/python-flickrapi-search-photos-returns-the-same-picture-on-every-page
        1 + (totalPages > 0 ? Int(arc4random()) % 100 : totalPages)
    }

    func getPhoto(from url: URL, completion: @escaping (Data?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            guard let data = data else {
                print("No data returned or there was an error.")
                completion(nil)
                return
            }

            DispatchQueue.main.async {
                completion(data)
            }
        }
        task.resume()
    }

    func getLocationAlbum(latitude: Double, longitude: Double, completion: @escaping ([String]) -> Void) {
        let url = getAlbumURL(latitude: latitude, longitude: longitude)
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let photos = json["photos"] as? [String: Any],
                let pages = photos["pages"] as? Int,
                let photo = photos["photo"] as? [[String: Any]]
            else {
                print("Invalid JSON")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            let imagesURLs: [String] = photo.compactMap {
                self.getImageURL(photo: $0)
            }

            self.totalPages = pages

            DispatchQueue.main.async {
                completion(imagesURLs)
            }
        }
        task.resume()
    }

    private func getAlbumURL(latitude: Double, longitude: Double) -> URL {
        var urlComponent = URLComponents()

        urlComponent.scheme = FlickrGateway.scheme
        urlComponent.host = FlickrGateway.host
        urlComponent.path = FlickrGateway.path

        urlComponent.queryItems = [
            URLQueryItem(name: FlickrGateway.methodParam, value: FlickrGateway.searchMethodValue),
            URLQueryItem(name: FlickrGateway.apiKeyParam, value: FlickrGateway.apiKey),
            URLQueryItem(name: FlickrGateway.latitudeParam, value: "\(latitude)"),
            URLQueryItem(name: FlickrGateway.longitudeParam, value: "\(longitude)"),
            URLQueryItem(name: FlickrGateway.radiusParam, value: "\(FlickrGateway.radiusValue)"),
            URLQueryItem(name: FlickrGateway.perPageParam, value: "\(FlickrGateway.perPageValue)"),
            URLQueryItem(name: FlickrGateway.pageParam, value: "\(randomPage)"),
            URLQueryItem(name: FlickrGateway.formatParam, value: FlickrGateway.formatValue),
            URLQueryItem(name: FlickrGateway.noJsonCallBackParam, value: "\(FlickrGateway.noJsonCallBackValue)")
        ]

        return urlComponent.url!
    }

    private func getImageURL(photo: [String: Any]) -> String? {
        guard let id = photo["id"] as? String,
            let farm = photo["farm"] as? Int,
            let server = photo["server"] as? String,
            let secret = photo["secret"] as? String else {
                return nil
        }

        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(FlickrGateway.photoSizeParam).jpg"
    }
}
