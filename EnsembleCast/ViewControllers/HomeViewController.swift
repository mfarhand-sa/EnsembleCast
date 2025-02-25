//
//  HomeViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//


import UIKit
import Combine

// MARK: - HomeViewController
class HomeViewController: UIViewController {
    
    private let transitionDelegate = SearchTransitionDelegate(isPresenting: true)
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Search movies...", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.contentHorizontalAlignment = .center
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    private let backgroundScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startBackgroundScrolling()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        // Background scroll view for movie covers
        view.addSubview(backgroundScrollView)
        NSLayoutConstraint.activate([
            backgroundScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        addBackgroundImages()
        
        // Add dim view on top of scroll view
         view.addSubview(dimView)
         NSLayoutConstraint.activate([
             dimView.topAnchor.constraint(equalTo: view.topAnchor),
             dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
             dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
             dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
         ])
        
        // Search TextField
        view.addSubview(searchButton)
        NSLayoutConstraint.activate([
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            searchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            searchButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        searchButton.addTarget(self, action: #selector(searchTapped), for: .touchUpInside)
    }
    
    private func addBackgroundImages() {
        let movieCovers = ["1", "2", "3", "4","5","6", "7"] // Replace with your image asset names
        var previousImageView: UIImageView?
        
        for cover in movieCovers {
            let imageView = UIImageView(image: UIImage(named: cover))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            backgroundScrollView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: backgroundScrollView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: backgroundScrollView.bottomAnchor),
                imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
                imageView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
            
            if let previous = previousImageView {
                imageView.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
            } else {
                imageView.leadingAnchor.constraint(equalTo: backgroundScrollView.leadingAnchor).isActive = true
            }
            
            previousImageView = imageView
        }
        
        previousImageView?.trailingAnchor.constraint(equalTo: backgroundScrollView.trailingAnchor).isActive = true
        backgroundScrollView.contentSize = CGSize(width: view.frame.width * CGFloat(movieCovers.count), height: view.frame.height)
        
    }
    
    
    private func startBackgroundScrolling() {
        let totalWidth = backgroundScrollView.contentSize.width
        if totalWidth <= view.frame.width { return }  // Skip if not wide enough to scroll
        
        // Set scroll speed (higher = faster)
        let scrollSpeed: CGFloat = 30.0 // Pixels per second
        let duration = Double(totalWidth / scrollSpeed)
        
        func animateScroll() {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear], animations: {
                self.backgroundScrollView.contentOffset.x = totalWidth - self.view.frame.width
            }) { _ in
                self.backgroundScrollView.contentOffset.x = 0
                animateScroll() // Infinite loop
            }
        }
        
        animateScroll()
    }
    
    
    @objc private func searchTapped() {
        let movieVC = MovieViewController()
        
        let navController = UINavigationController(rootViewController: movieVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    
    
}
