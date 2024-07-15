//
//  ToolbarButton.swift
//  barracuta
//
//  Created by samara on 1/15/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import Foundation
import UIKit

protocol JBButtonDelegate: AnyObject { func jbButtonDidFinishAction(_ button: jbButton) }

enum ButtonState {
    case done
    case jailbreak
    case jailbreaking
    case error
    case unsupported
}

class jbButton: UIButton {
    weak var delegate: JBButtonDelegate?

    var currentState: ButtonState
    private var activityIndicator: UIActivityIndicatorView!

    init(state: ButtonState) {
        self.currentState = state
        super.init(frame: .zero)
        
        configureButton(for: state)
        addTarget(self, action: #selector(jbTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func configureButton(for state: ButtonState) {

        UIView.animate(withDuration: 0.2) {
            self.alpha = 0.2
        } completion: { _ in
            self.layer.cornerRadius = 10
            self.frame = CGRect(x: 0, y: 0, width: 0, height: 40)
            self.setTitleColor(.white, for: .normal)
            self.layer.borderWidth = 0
            self.activityIndicator?.removeFromSuperview()
            self.activityIndicator = nil

            switch state {
            case .done:
                self.isEnabled = true
                self.backgroundColor = .systemGreen
                self.setTitle("Userspace Reboot", for: .normal)
            case .jailbreak:
                self.backgroundColor = .systemPink
                self.setTitle("Jailbreak", for: .normal)
            case .jailbreaking:
                self.isEnabled = false
                self.backgroundColor = .systemPink.withAlphaComponent(0.2)
                self.setTitle("", for: .normal)
                self.layer.borderWidth = 1
                self.layer.borderColor = UIColor.systemPink.withAlphaComponent(0.6).cgColor
                self.showLoadingIndicator()
            case .error:
                self.isEnabled = false
                self.backgroundColor = .systemOrange.withAlphaComponent(0.2)
                self.setTitle("Error", for: .normal)
                self.setTitleColor(.systemOrange, for: .normal)
                self.layer.borderWidth = 1
                self.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.6).cgColor
            case .unsupported:
                self.isEnabled = false
                self.backgroundColor = .systemPink.withAlphaComponent(0.2)
                self.setTitle("Unsupported", for: .normal)
                self.setTitleColor(.systemPink, for: .normal)
                self.layer.borderWidth = 1
                self.layer.borderColor = UIColor.systemPink.withAlphaComponent(0.6).cgColor
            }

            UIView.animate(withDuration: 0.3) { self.alpha = 1.0 }
        }
    }



    private func showLoadingIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        activityIndicator.startAnimating()
    }
    
    @objc private func jbTapped() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        switch currentState {
        case .done:
            userspaceReboot()
        case .jailbreak:
            Logger.shared.log(logType: .standard, subTitle: "Starting jailbreak process")
            delegate?.jbButtonDidFinishAction(self)
        default:
            break
        }
    }

    
    func updateButtonState(_ newState: ButtonState) {
        currentState = newState
        configureButton(for: newState)
    }
}
