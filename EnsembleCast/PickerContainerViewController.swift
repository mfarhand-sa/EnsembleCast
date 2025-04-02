//
//  PickerContainerViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-03-31.
//

import Photos
import PhotosUI

class PickerContainerViewController: UIViewController {
    let pickerVC: PHPickerViewController

    init(configuration: PHPickerConfiguration) {
        self.pickerVC = PHPickerViewController(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(pickerVC)
        view.addSubview(pickerVC.view)
        pickerVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            pickerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pickerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        pickerVC.didMove(toParent: self)
    }
}
