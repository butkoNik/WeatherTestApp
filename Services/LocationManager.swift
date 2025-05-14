import Foundation
import CoreLocation

enum LocationError: Error {
    case denied
    case restricted
    case unknown
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let manager = CLLocationManager()
    
    private var locationPromise: ((Result<CLLocation, Error>) -> Void)?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() async throws -> CLLocation {
        let moscowLocation = CLLocation(latitude: 55.7558, longitude: 37.6173)
        
        if CLLocationManager.locationServicesEnabled() {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                return moscowLocation
            case .authorizedWhenInUse, .authorizedAlways:
                break
            @unknown default:
                throw LocationError.unknown
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationPromise = continuation.resume
            manager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationPromise?(.success(location))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationPromise?(.failure(error))
    }
} 
