//
//  JailbreakViewController.swift
//  barracuta
//
//  Created by samara on 1/14/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import UIKit

class JailbreakViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LoggerDelegate {

    let tableView = UITableView()
    let cellReuseIdentifier = "Cell"
    let settingsManager = SettingsManager.shared

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 44.0)))
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        let toolbarHeight: CGFloat = 70

        let jbButton = jbButton(state: .jailbreak)
        jbButton.delegate = self
        let fileListHeaderItem = UIBarButtonItem(customView: jbButton)

        toolbar.setItems([fileListHeaderItem], animated: false)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        
        Logger.shared.delegate = self

        tableView.separatorStyle = .none
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "Cell")
        Logger.shared.log(logType: .standard, subTitle: "Supported Versions: 16.0 - 16.6.1")
        tableView.reloadData()
    }
    
    func didAddNewLog() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            let indexPath = IndexPath(row: Logger.shared.data.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Logger.shared.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! CustomTableViewCell
        cell.configure(with: Logger.shared.data[indexPath.row])
        return cell
    }
}

extension JailbreakViewController: JBButtonDelegate {
    func jbButtonDidFinishAction(_ button: jbButton) {
        
        button.updateButtonState(.jailbreaking)

        DispatchQueue.global().async { [self] in
            Logger.shared.log(logType: .success, subTitle: "Exploiting kernel")

            do_kopen(UInt64(settingsManager.puafPages), UInt64(settingsManager.puafMethod), UInt64(settingsManager.kreadMethod), UInt64(settingsManager.kwriteMethod), settingsManager.staticHeadroom, settingsManager.useMemoryHogger)
            
            Logger.shared.log(logType: .success, subTitle: "Jailbreaking")
            
//            go2()
            go(settingsManager.isBetaIos, "reinstall")
            Logger.shared.log(logType: .success, subTitle: "Installing...")

            do_kclose()
            Logger.shared.log(logType: .success, subTitle: "Cleaned up")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                button.updateButtonState(.done)
            }
        }
    }
}
