//
//  MainTabBarController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-25.
//


import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }

    private func setupTabBar() {
        // Movie Tab
        let movieViewController = MovieViewController()
        let movieNavController = UINavigationController(rootViewController: movieViewController)
        movieNavController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "search-unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "search-selected")?.withRenderingMode(.alwaysOriginal)
        )

        // Favourites Tab (Placeholder View Controller)
        let favouritesViewController = UIViewController()
        favouritesViewController.view.backgroundColor = .systemBackground
        favouritesViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage(named: "favourite-unselected")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "favourite-selected")?.withRenderingMode(.alwaysOriginal)
        )

        // Set the ViewControllers
        viewControllers = [movieNavController, favouritesViewController]

        // Tab Bar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground  // Dark: Black, Light: White

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .label  // Active tab icon color
        tabBar.unselectedItemTintColor = .gray  // Inactive tab icon color
    }
}
