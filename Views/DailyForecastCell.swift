import UIKit

final class DailyForecastCell: UITableViewCell {
    static let reuseIdentifier = "DailyForecastCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tempRangeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.addSubview(dayLabel)
        contentView.addSubview(tempRangeLabel)
        
        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            tempRangeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tempRangeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with forecastDay: ForecastDay) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: forecastDay.date) {
            dateFormatter.dateFormat = "EEEE"
            dayLabel.text = dateFormatter.string(from: date)
        }
        
        tempRangeLabel.text = "\(Int(round(forecastDay.day.mintempC)))° - \(Int(round(forecastDay.day.maxtempC)))°"
    }
} 