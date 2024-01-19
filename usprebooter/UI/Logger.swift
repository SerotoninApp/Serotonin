//
//  Logger.swift
//  barracuta
//
//  Created by samara on 1/15/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import Foundation
import UIKit

protocol LoggerDelegate: AnyObject { func didAddNewLog() }

class Logger {
    static let shared = Logger()
    weak var delegate: LoggerDelegate?

    var data: [InfoLogModel] = []

    func log(logType: LogType, subTitle: String) {
        let newUser = InfoLogModel(logType: logType, subTitleLabel: subTitle)
        data.append(newUser)
        delegate?.didAddNewLog()
    }
}

enum LogType: String {
    case standard = "Info"
    case error    = "Error"
    case warning  = "Warning"
    case success  = "Success"
}

class InfoLogModel {
    var logType: LogType
    var subTitleLabel: String?

    init(logType: LogType, subTitleLabel: String) {
        self.logType = logType
        self.subTitleLabel = subTitleLabel
    }
}

class CustomTableViewCell: UITableViewCell {
    
    let backView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        view.layer.borderWidth = 1.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.label
        label.numberOfLines = 0 // Allow multiple lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 0 // Allow multiple lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
        setupConstraints()
    }
    
    func setupViews() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        backView.layer.cornerRadius = 15
        backView.clipsToBounds = true
        addSubview(backView)
        backView.addSubview(titleLabel)
        backView.addSubview(subTitleLabel)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            backView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            backView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            backView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            backView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            
            titleLabel.topAnchor.constraint(equalTo: backView.topAnchor, constant: 23),
            titleLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            
            subTitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subTitleLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 16),
            subTitleLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -16),
            subTitleLabel.bottomAnchor.constraint(equalTo: backView.bottomAnchor, constant: -24)
        ])
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        selectionStyle = .none
    }
    
    func configure(with infoLog: InfoLogModel) {
        titleLabel.text = infoLog.logType.rawValue
        subTitleLabel.text = infoLog.subTitleLabel

        switch infoLog.logType {
        case .standard:
            backView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.4)
            backView.layer.borderColor = UIColor.secondarySystemBackground.cgColor
        case .error:
            backView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
            backView.layer.borderColor = UIColor.systemRed.cgColor
        case .warning:
            backView.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.3)
            backView.layer.borderColor = UIColor.systemYellow.cgColor
        case .success:
            backView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            backView.layer.borderColor = UIColor.systemGreen.cgColor
        }

        // Adjust constraints based on the content size
        let height = contentView.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: .greatestFiniteMagnitude),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        backView.frame.size.height = height
    }
}

