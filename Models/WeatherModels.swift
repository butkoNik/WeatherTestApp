import Foundation

struct CurrentWeatherResponse: Codable {
    let location: Location
    let current: Current
}

struct Location: Codable {
    let name: String
    let region: String
    let country: String
    let lat: Double
    let lon: Double
    let localtime: String
}

struct Current: Codable {
    let tempC: Double
    let tempF: Double
    let isDay: Int
    let condition: Condition
    let windKph: Double
    let windDir: String
    let humidity: Int
    let feelslikeC: Double
    
    enum CodingKeys: String, CodingKey {
        case tempC = "temp_c"
        case tempF = "temp_f"
        case isDay = "is_day"
        case condition
        case windKph = "wind_kph"
        case windDir = "wind_dir"
        case humidity
        case feelslikeC = "feelslike_c"
    }
}

struct ForecastResponse: Codable {
    let location: Location
    let current: Current
    let forecast: Forecast
}

struct Forecast: Codable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Codable {
    let date: String
    let day: Day
    let hour: [Hour]
}

struct Day: Codable {
    let maxtempC: Double
    let mintempC: Double
    let condition: Condition
    
    enum CodingKeys: String, CodingKey {
        case maxtempC = "maxtemp_c"
        case mintempC = "mintemp_c"
        case condition
    }
}

struct Hour: Codable {
    let time: String
    let tempC: Double
    let condition: Condition
    
    enum CodingKeys: String, CodingKey {
        case time
        case tempC = "temp_c"
        case condition
    }
}

struct Condition: Codable {
    let text: String
    let icon: String
    let code: Int
} 
