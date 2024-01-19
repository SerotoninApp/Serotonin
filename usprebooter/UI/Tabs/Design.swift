//
//  Design.swift
//  barracuta
//
//  Created by samara on 1/14/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import Foundation
import UIKit

class CustomSectionHeader: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        setupUI()
        self.title = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var title: String {
        get {
            return titleLabel.text ?? ""
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
        ])
    }
}

struct CreditsPerson {
    let name: String
    let role: String
    let pfpURL: URL
    let socialLink: URL?
}

class PersonCell: UITableViewCell {
    var personImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 22.5
        imageView.clipsToBounds = true
        
        return imageView
    }()


    var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    var roleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    func configure(with person: CreditsPerson) {
        nameLabel.text = person.name
        roleLabel.text = person.role

        URLSession.shared.dataTask(with: person.pfpURL) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.personImageView.image = uiImage
                }
            }
        }
        .resume()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.addSubview(personImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(roleLabel)

        NSLayoutConstraint.activate([
            personImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            personImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            personImageView.widthAnchor.constraint(equalToConstant: 45),
            personImageView.heightAnchor.constraint(equalToConstant: 45),

            nameLabel.leadingAnchor.constraint(equalTo: personImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            roleLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            roleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            roleLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            roleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
}

func createAccessoryView(systemImageName: String) -> UIView {
    if let arrowImage = UIImage(systemName: systemImageName)?.withTintColor(UIColor.tertiaryLabel, renderingMode: .alwaysOriginal) {
        let accessoryView = UIImageView(image: arrowImage)
        return accessoryView
    }
    return UIView()
}


extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

class AboutHeaderView: UIView {
    private var titleLabel: UILabel!
    private var versionLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHeaderView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureHeaderView()
    }

    func configureHeaderView() {
        backgroundColor = .clear

        var title = ""
        var versionString = ""

        if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String,
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            title = appName
            versionString = "Version \(appVersion) (Build \(buildVersion))"
        }

        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = UIColor.label
        titleLabel.numberOfLines = 0
        titleLabel.sizeToFit()
        titleLabel.center = CGPoint(x: center.x, y: center.y - titleLabel.frame.height / 2)

        versionLabel = UILabel()
        versionLabel.text = versionString
        versionLabel.font = UIFont.systemFont(ofSize: 14)
        versionLabel.textColor = UIColor.secondaryLabel
        versionLabel.numberOfLines = 0
        versionLabel.sizeToFit()
        versionLabel.center = CGPoint(x: center.x, y: center.y + versionLabel.frame.height / 2)

        addSubview(titleLabel)
        addSubview(versionLabel)
        center.x = superview?.center.x ?? 0
    }
}
