//
//  LicensesViewController.swift
//  barracuta
//
//  Created by samara on 1/15/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import Foundation
import UIKit

class LicensesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var fileNames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Licenses"
        
        if let mdFiles = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath).filter({ $0.hasSuffix(".md") }) {
            fileNames = mdFiles
        }
        
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
                
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = fileNames[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedFileName = fileNames[indexPath.row]
        
        if let fileContents = loadFileContents(fileName: selectedFileName) {
            let textViewController = TextViewController()
            textViewController.textContent = fileContents
            textViewController.titleText = selectedFileName
            navigationController?.pushViewController(textViewController, animated: true)
        }
    }
    
    private func loadFileContents(fileName: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: ""),
              let fileContents = try? String(contentsOfFile: filePath) else {
            return nil
        }
        return fileContents
    }


}

class TextViewController: UIViewController {
    
    var textContent: String?
    var titleText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText
        let textView = UITextView()
        textView.text = textContent
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        let monospacedFont = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .regular)
        textView.font = monospacedFont
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
