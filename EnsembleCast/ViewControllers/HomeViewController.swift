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
    
    private let startHuntingButton: HFButton = {
        let button = HFButton(type: .system)
        button.setTitle("START HUNTING", for: .normal)
        button.setTitleColor(UIColor(red: 0.06, green: 0.09, blue: 0.13, alpha: 1.0), for: .normal)
        button.backgroundColor = .white
        button.titleLabel?.font = .CDFontMedium(size: 20)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Movies\nare worth\nthe hunt."
        label.numberOfLines = 3
        label.font = .CDFontSemiBold(size: 64)
        label.textColor = .white
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let backgroundScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isPagingEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alpha = 0.1
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startBackgroundScrolling()
    }
    
    
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        edgesForExtendedLayout = .all
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        view.addSubview(backgroundScrollView)
        NSLayoutConstraint.activate([
            backgroundScrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            backgroundScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        addBackgroundImages()
        
        // Add Gradient View
        addGradientLayer()
        
        // Add "START HUNTING" Button
        view.addSubview(startHuntingButton)
        NSLayoutConstraint.activate([
            startHuntingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            startHuntingButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 37),
            startHuntingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -37),
            startHuntingButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        startHuntingButton.addTarget(self, action: #selector(startHuntingTapped), for: .touchUpInside)
        
        
        // Add Title
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.bottomAnchor.constraint(equalTo: startHuntingButton.topAnchor, constant: -30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 37),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        configureTitleLabel()
        
    }
    
    private func configureTitleLabel() {
        let text = "Movies\nare worth\nthe hunt."
        let attributedString = NSMutableAttributedString(string: text)
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = -10
        paragraphStyle.minimumLineHeight = 74
        paragraphStyle.maximumLineHeight = 74
        paragraphStyle.alignment = .left
        
        // Apply white color for all text.
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        
        // Apply purple color to "the hunt."
        if let range = text.range(of: "the hunt.") {
            let nsRange = NSRange(range, in: text)
            let purpleColor = UIColor(red: 0.74, green: 0.35, blue: 0.89, alpha: 1.0)
            attributedString.addAttribute(.foregroundColor, value: purpleColor, range: nsRange)
        }
        
        titleLabel.baselineAdjustment = .alignBaselines
        titleLabel.clipsToBounds = false
        titleLabel.attributedText = attributedString
    }
    
    
    
    
    private func addGradientLayer() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.06, green: 0.09, blue: 0.13, alpha: 1.0).cgColor,
            UIColor(red: 0.14, green: 0.09, blue: 0.16, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = view.bounds
        
        // Ensure the gradient is below the images but above the background
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    
    
    private func addBackgroundImages() {
        let movieCovers = ["1", "2", "3", "4","5","6", "7"]
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
        if totalWidth <= view.frame.width { return }
        
        // Set scroll speed (higher = faster)
        let scrollSpeed: CGFloat = 30.0 // Pixels per second
        let duration = Double(totalWidth / scrollSpeed)
        
        func animateScroll() {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear], animations: {
                self.backgroundScrollView.contentOffset.x = totalWidth - self.view.frame.width
            }) { _ in
                self.backgroundScrollView.contentOffset.x = 0
                animateScroll()
            }
        }
        
        animateScroll()
    }
    
    
    @objc private func startHuntingTapped() {
        let tabbarVC = MainTabBarController()
        updateRootViewController(to: tabbarVC)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let gradientLayer = view.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
    
}
