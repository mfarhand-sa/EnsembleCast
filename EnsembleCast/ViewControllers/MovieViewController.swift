//
//  ExploreViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//

import UIKit
import Combine
import Kingfisher

// MARK: - ExploreViewController

class ExploreViewController: UIViewController {
    

    // The two children
    private let homeVC = HomeChildViewController()
    private let searchVC = SearchChildViewController()
    private lazy var searchController: UISearchController = {
        
        // Set up search controller
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search Movies"
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.tintColor = .label
        return searchController
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addChildVC(homeVC)
        homeVC.didMove(toParent: self)
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupNavigation()
        // Add search controller to the navigation bar
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupNavigation() {
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Explore"
    }
    

    
}



// MARK: - UISearchControllerDelegate
extension ExploreViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        // Switch from Home to Search child
        removeChild(homeVC)
        addChildVC(searchVC)
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        // Switch back from Search child to Home
        removeChild(searchVC)
        addChildVC(homeVC)
    }
}

// MARK: - Helpers to Add/Remove Child VCs
extension ExploreViewController {
    private func addChildVC(_ child: UIViewController) {
        addChild(child)

        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        child.didMove(toParent: self)
    }


    private func removeChild(_ child: UIViewController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }
}


extension ExploreViewController: UISearchBarDelegate {
  
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
          // Forward this to your child
          searchVC.updateSearchQuery(searchText)
      }
      
      func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
          searchVC.clearSearch()
      }
}


