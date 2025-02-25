//
//  AppCoordinator.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//

import UIKit
// MARK: - AppCoordinator
class AppCoordinator {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let homeViewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: homeViewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
