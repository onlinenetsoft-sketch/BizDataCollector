import Foundation
import Combine

class APIScraper {
    private let rateLimiter = RateLimiter(requestsPerSecond: 0.5) // 2-second delay
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Example using Yelp Fusion API (ethical, approved access)
    func fetchBusinesses(category: String, location: String, completion: @escaping ([BusinessListing]) -> Void) {
        guard let apiKey = ProcessInfo.processInfo.environment["YELP_API_KEY"] else {
            print("Error: Yelp API key not configured. See setup instructions.")
            completion([])
            return
        }
        
        let endpoint = "https://api.yelp.com/v3/businesses/search"
        var components = URLComponents(string: endpoint)!
        components.queryItems = [
            URLQueryItem(name: "term", value: category),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "limit", value: "50") // API limit
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Enforce rate limiting
        rateLimiter.perform {
            URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { output in
                    guard let response = output.response as? HTTPURLResponse,
                          response.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                    return output.data
                }
                .decode(type: YelpSearchResponse.self, decoder: JSONDecoder())
                .map { response in
                    response.businesses.map { business in
                        BusinessListing(
                            name: business.name,
                            category: business.categories.first?.title ?? "Uncategorized",
                            address: business.location.address1 ?? "",
                            city: business.location.city,
                            province: business.location.state,
                            postalCode: business.location.zipCode ?? "",
                            phone: business.phone ?? "",
                            url: business.url,
                            latitude: business.coordinates.latitude,
                            longitude: business.coordinates.longitude
                        )
                    }
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    if case .failure(let error) = result {
                        print("API Error: \(error.localizedDescription)")
                    }
                }, receiveValue: { listings in
                    completion(listings)
                })
                .store(in: &self.cancellables)
        }
    }
}

// Supporting Yelp API models
private struct YelpSearchResponse: Codable {
    let businesses: [YelpBusiness]
}

private struct YelpBusiness: Codable {
    let name: String
    let categories: [YelpCategory]
    let location: YelpLocation
    let phone: String?
    let url: String?
    let coordinates: YelpCoordinates
}

private struct YelpCategory: Codable {
    let title: String
}

private struct YelpLocation: Codable {
    let address1: String?
    let city: String
    let state: String
    let zipCode: String?
}

private struct YelpCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}