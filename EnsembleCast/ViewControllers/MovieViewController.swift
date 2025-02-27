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
    
    private var gradientLayer: CAGradientLayer?
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupNavigation()
        addGradientLayer()
    }
    
    
    private func addGradientLayer() {
        gradientLayer?.removeFromSuperlayer()
        
        let newGradientLayer = CAGradientLayer()
        newGradientLayer.colors = [
            UIColor(named: "GradientStart")!.cgColor,
            UIColor(named: "GradientEnd")!.cgColor
        ]
        newGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        newGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        newGradientLayer.frame = view.bounds
        view.layer.insertSublayer(newGradientLayer, at: 0)
        gradientLayer = newGradientLayer
    }
    
    private func setupNavigation() {
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.shadowColor = .clear
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true
        self.title = "Explore"
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            addGradientLayer()
        }
    }
}

extension ExploreViewController: SearchChildDelegate {
    func dismissKeyboard() {
        self.searchController.searchBar.resignFirstResponder()
    }
}



// MARK: - UISearchControllerDelegate
extension ExploreViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        removeChild(homeVC)
        addChildVC(searchVC)
        searchVC.delegate = self
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
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
        searchVC.updateSearchQuery(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchVC.clearSearch()
    }
}


