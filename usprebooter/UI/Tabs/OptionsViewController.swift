//
//  a.swift
//  barracuta
//
//  Created by samara on 1/14/24.
//  Copyright © 2024 samiiau. All rights reserved.
//

import Foundation
import Darwin
import UIKit

class OptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var tableView: UITableView!
    var tableData = [
        ["About", "Changelogs"],
        ["Beta iOS", "Verbose Boot", "Hide Internal Text"],
        ["PUAF Pages", "PUAF Method", "KRead Method", "KWrite Method" ,"Use Memory Hogger"],
        ["Set Defaults"]
    ]

    var sectionTitles = ["", "Options", "Exploit", ""]
    
    let puaf_method_options = [ "physpuppet", "smith", "landa" ]
    let kread_method_options = [ "kqueue_workloop_ctl", "sem_open" ]
    let kwrite_method_options = [ "dup", "sem_open" ]
    
    var settingsManager = SettingsManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        self.title = "Options"
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        updateTableDataForMemoryHogger()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int { return sectionTitles.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return tableData[section].count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sectionTitles[section] }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return sectionTitles[section].isEmpty ? 20 : 40 }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title = sectionTitles[section]
        let headerView = CustomSectionHeader(title: title)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none
        cell.accessoryType = .none

        let cellText = tableData[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellText
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16.0)

        switch cellText {
        case "About":
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            
        case "Changelogs":
            cell.accessoryView = createAccessoryView(systemImageName: "doc.plaintext")
            cell.selectionStyle = .default

        case "Set Defaults":
            cell.textLabel?.textColor = UIColor(named: "AccentColor")
            cell.selectionStyle = .default
            
        case "Headroom":
            let slider = UISlider()
            slider.setValue(Float(settingsManager.staticHeadroom), animated: false);
            slider.minimumValue = 4
            slider.maximumValue = log2(Float(getPhysicalMemorySize() / 1048576) / 1.3)
            slider.addTarget(self, action: #selector(headroomValueChanged(_:)), for: .valueChanged)

            cell.accessoryView = slider
            cell.detailTextLabel?.text = "\(settingsManager.staticHeadroom) MB"
            
        case "PUAF Pages":
            let slider = UISlider()
            slider.setValue(Float(settingsManager.puafPages), animated: false);
            slider.minimumValue = 4
            slider.maximumValue = 15
            slider.addTarget(self, action: #selector(puafValueChanged(_:)), for: .valueChanged)

            cell.accessoryView = slider
            cell.detailTextLabel?.text = "\(settingsManager.puafPages)"
            
        case "PUAF Method":
            let _ = createPickerButton(in: cell, with: puaf_method_options, currentValue: puaf_method_options[settingsManager.puafMethod], actionHandler: puafMethodChanged);
            
        case "KRead Method":
            let _ = createPickerButton(in: cell, with: kread_method_options, currentValue: kread_method_options[settingsManager.kreadMethod], actionHandler: kreadMethodChanged);
            
        case "KWrite Method":
            let _ = createPickerButton(in: cell, with: kwrite_method_options, currentValue: kread_method_options[settingsManager.kwriteMethod], actionHandler: kwriteMethodChanged);
    
        case "Beta iOS", "Verbose Boot", "Hide Internal Text", "Use Memory Hogger":
            let switchView = UISwitch()
            switchView.isOn = switchStateForSetting(cellText)
            switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
            cell.accessoryView = switchView
            
        default:
            break
        }
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 13.0)
        return cell
    }
    
    @objc func headroomValueChanged(_ sender: UISlider) {
        let roundedValue = roundLog(sender.value)
        sender.value = roundedValue

        settingsManager.staticHeadroom = Int(pow(Double(2), Double(roundedValue)));

        if let sectionIndex = sectionTitles.firstIndex(of: "Exploit"),
           let rowIndex = tableData[sectionIndex].firstIndex(of: "Headroom") {

            let indexPath = IndexPath(row: rowIndex, section: sectionIndex)

            if let cell = tableView.cellForRow(at: indexPath) {
                cell.detailTextLabel?.text = "\(settingsManager.staticHeadroom) MB"
            }
        }
    }
    
    @objc func puafValueChanged(_ sender: UISlider) {
        let roundedValue = roundLog(sender.value)
        sender.value = roundedValue

        settingsManager.puafPages = Int(pow(Double(2), Double(roundedValue)));

        if let sectionIndex = sectionTitles.firstIndex(of: "Exploit"),
           let rowIndex = tableData[sectionIndex].firstIndex(of: "PUAF Pages") {

            let indexPath = IndexPath(row: rowIndex, section: sectionIndex)

            if let cell = tableView.cellForRow(at: indexPath) {
                cell.detailTextLabel?.text = "\(settingsManager.puafPages)"
            }
        }
    }
    
    @objc func puafMethodChanged(_ method: String) {
        switch method {
        case "physpuppet":
            settingsManager.puafMethod = 0;
        case "smith":
            settingsManager.puafMethod = 1;
        case "landa":
            settingsManager.puafMethod = 2;
        default:
            break;
        }
    }
    
    @objc func kreadMethodChanged(_ method: String) {
        switch method {
        case "kqueue_workloop_ctl":
            settingsManager.kreadMethod = 0;
        case "sem_open":
            settingsManager.kreadMethod = 1;
        default:
            break;
        }
    }
    
    @objc func kwriteMethodChanged(_ method: String) {
        switch method {
        case "dup":
            settingsManager.kwriteMethod = 0;
        case "sem_open":
            settingsManager.kwriteMethod = 1;
        default:
            break;
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellText = tableData[indexPath.section][indexPath.row]

        switch cellText {
        case "Set Defaults":
            settingsManager.resetToDefaultDefaults()
            UIView.transition(with: tableView, duration: 0.4, options: .transitionCrossDissolve, animations: {
                tableView.reloadData() // Update the table to reflect the changes with animation
            }, completion: nil)
        case "About":
            let aboutView = AboutViewController()
            navigationController?.pushViewController(aboutView, animated: true)
        case "Changelogs":
            let cView = ChangelogViewController()
            navigationController?.pushViewController(cView, animated: true)
        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    @objc func switchChanged(_ sender: UISwitch) {
        guard let cell = findCell(for: sender) else {
            return
        }
        
        if let indexPath = tableView.indexPath(for: cell) {
            let setting = tableData[indexPath.section][indexPath.row]
            switch setting {
            case "Beta iOS":
                settingsManager.isBetaIos = sender.isOn
            case "Verbose Boot":
                settingsManager.verboseBoot = sender.isOn
            case "Use Memory Hogger":
                settingsManager.useMemoryHogger = sender.isOn
                updateTableDataForMemoryHogger()
                tableView.reloadSections(IndexSet(integer: 2), with: .fade)
            case "Hide Internal Text":
                settingsManager.hideInternalText = sender.isOn
            default:
                break
            }
        }
    }
    
    private func updateTableDataForMemoryHogger() {
        if settingsManager.useMemoryHogger {
            tableData[2].append("Headroom")
        } else {
            if let index = tableData[2].firstIndex(of: "Headroom") {
                tableData[2].remove(at: index)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            return "You can leave these settings as default if you don't know what they do."
        default:
            return nil
        }
    }
}



// MARK: - Other




extension OptionsViewController {
    private func switchStateForSetting(_ setting: String) -> Bool {
        switch setting {
        case "Beta iOS":
            return settingsManager.isBetaIos
        case "Verbose Boot":
            return settingsManager.verboseBoot
        case "Hide Internal Text":
            return settingsManager.hideInternalText
        case "Use Memory Hogger":
            return settingsManager.useMemoryHogger
        default:
            return false
        }
    }
    
    private func findCell(for switchView: UISwitch) -> UITableViewCell? {
        var view = switchView
        while let superview = view.superview {
            if let cell = superview as? UITableViewCell {
                return cell
            }
            view = superview as! UISwitch
        }
        return nil
    }
    
    private func createPickerButton<T: Hashable & CustomStringConvertible>(
        in cell: UITableViewCell,
        with options: [T],
        currentValue: T,
        actionHandler: @escaping (T) -> Void
    ) -> UIButton {
        let cfg = UIButton.Configuration.plain()
        let pickerButton = UIButton(configuration: cfg)
        
        let menuItems: [UIAction] = options.map { option in
            UIAction(title: option.description, state: (option == currentValue) ? .on : .off) { action in
                actionHandler(option)
            }
        }
        
        let fontMenu = UIMenu(options: [.singleSelection], children: menuItems)
        
        pickerButton.menu = fontMenu
        pickerButton.showsMenuAsPrimaryAction = true
        pickerButton.changesSelectionAsPrimaryAction = true
        
        if let detailTextColor = cell.detailTextLabel?.textColor {
            pickerButton.setTitleColor(detailTextColor, for: .normal)
            pickerButton.tintColor = .tertiaryLabel
        }
        cell.contentView.addSubview(pickerButton)
        
        pickerButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -4),
            pickerButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
        ])
        
        return pickerButton
    }
}
