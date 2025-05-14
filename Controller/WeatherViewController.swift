import UIKit
import SnapKit

final class WeatherViewController: UIViewController {
    private let currentWeatherView = CurrentWeatherView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorView = UIView()
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let retryButton = UIButton(type: .system)
    
    private lazy var hourlyCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 80)
        layout.minimumInteritemSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(HourlyForecastCell.self, forCellWithReuseIdentifier: HourlyForecastCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var dailyTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.register(DailyForecastCell.self, forCellReuseIdentifier: DailyForecastCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private var hourlyForecast: [Hour] = []
    private var dailyForecast: [ForecastDay] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchWeatherData()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)

        view.addSubview(currentWeatherView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorView)
        errorView.addSubview(errorLabel)
        errorView.addSubview(retryButton)
        view.addSubview(hourlyCollectionView)
        view.addSubview(dailyTableView)

        loadingIndicator.color = .white

        retryButton.setTitle("Retry", for: .normal)
        retryButton.tintColor = .white
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)

        errorView.isHidden = true

        currentWeatherView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(200)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        errorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
        }

        retryButton.snp.makeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        hourlyCollectionView.snp.makeConstraints { make in
            make.top.equalTo(currentWeatherView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(100)
        }

        dailyTableView.snp.makeConstraints { make in
            make.top.equalTo(hourlyCollectionView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    @objc private func retryButtonTapped() {
        fetchWeatherData()
    }
    
    private func fetchWeatherData() {
        showLoading()
        
        Task {
            do {
                let location = try await LocationManager.shared.requestLocation()
                async let currentWeather = NetworkManager.shared.fetchCurrentWeather(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                async let forecast = NetworkManager.shared.fetchForecast(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                
                let (currentResponse, forecastResponse) = try await (currentWeather, forecast)
                
                await MainActor.run {
                    self.updateUI(with: currentResponse, forecast: forecastResponse)
                    self.hideLoading()
                }
            } catch {
                await MainActor.run {
                    let errorMessage: String
                    switch error {
                    case NetworkError.invalidURL:
                        errorMessage = "Invalid URL configuration"
                    case NetworkError.serverError(let message):
                        errorMessage = "Server error: \(message)"
                    case NetworkError.decodingError(let decodingError):
                        errorMessage = "Failed to process weather data: \(decodingError.localizedDescription)"
                    case NetworkError.httpError(let statusCode):
                        errorMessage = "HTTP error: \(statusCode)"
                    case let locationError as LocationError:
                        errorMessage = "Location error: \(locationError)"
                    default:
                        errorMessage = "Failed to load weather data: \(error.localizedDescription)"
                    }
                    self.showError(message: errorMessage)
                }
            }
        }
    }
    
    private func showLoading() {
        loadingIndicator.startAnimating()
        errorView.isHidden = true
        currentWeatherView.isHidden = true
        hourlyCollectionView.isHidden = true
        dailyTableView.isHidden = true
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
        errorView.isHidden = true
        currentWeatherView.isHidden = false
        hourlyCollectionView.isHidden = false
        dailyTableView.isHidden = false
    }
    
    private func showError(message: String) {
        loadingIndicator.stopAnimating()
        errorLabel.text = message
        errorView.isHidden = false
        currentWeatherView.isHidden = true
        hourlyCollectionView.isHidden = true
        dailyTableView.isHidden = true
    }
    
    private func updateUI(with current: CurrentWeatherResponse, forecast: ForecastResponse) {
        currentWeatherView.configure(with: current.current, location: current.location)
        
        if let today = forecast.forecast.forecastday.first {
            let currentHour = Calendar.current.component(.hour, from: Date())
            hourlyForecast = Array(today.hour.dropFirst(currentHour))
            
            if let tomorrow = forecast.forecast.forecastday.dropFirst().first {
                hourlyForecast.append(contentsOf: tomorrow.hour)
            }
        }
        
        dailyForecast = forecast.forecast.forecastday
        print("Days in dailyForecast array: \(dailyForecast.count)")
        
        hourlyCollectionView.reloadData()
        dailyTableView.reloadData()
    }
}

// MARK: - DataSource & Delegate

extension WeatherViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hourlyForecast.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HourlyForecastCell.reuseIdentifier, for: indexPath) as! HourlyForecastCell
        cell.configure(with: hourlyForecast[indexPath.item])
        return cell
    }
}


extension WeatherViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("TableView requesting number of rows: \(dailyForecast.count)")
        return dailyForecast.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DailyForecastCell.reuseIdentifier, for: indexPath) as! DailyForecastCell
        print("Configuring cell for day \(indexPath.row)")
        cell.configure(with: dailyForecast[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

