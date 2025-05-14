import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case httpError(Int)
}

final class NetworkManager {
    static let shared = NetworkManager()
    private let apiKey = "fa8b3df74d4042b9aa7135114252304"
    private let baseURL = "https://api.weatherapi.com/v1"
    
    private init() {}
    
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> CurrentWeatherResponse {
        let endpoint = "\(baseURL)/current.json?key=\(apiKey)&q=\(latitude),\(longitude)"
        
        return try await performRequest(endpoint: endpoint)
    }
    
    func fetchForecast(latitude: Double, longitude: Double, days: Int = 7) async throws -> ForecastResponse {
        let endpoint = "\(baseURL)/forecast.json?key=\(apiKey)&q=\(latitude),\(longitude)&days=\(days)"
        
        let response: ForecastResponse = try await performRequest(endpoint: endpoint)
        let receivedDays = response.forecast.forecastday.count
        
        if receivedDays < days {
            print("Requested \(days) days but received only \(receivedDays) days.")
        }
        
        return response
    }
    
    private func performRequest<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else { throw NetworkError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response type")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
} 
