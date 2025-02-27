//
//  HomeChildViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//


import UIKit
import Combine

// MARK: - HomeViewController
class HomeChildViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hunt Through\n100K+ Movies."
        label.numberOfLines = 3
        label.font = .CDFontSemiBold(size: 48)
        label.textColor = .systemPink
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
        scrollView.alpha = 0.8
        return scrollView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startBackgroundScrolling()
    }
    
    
    private func setupUI() {
        view.backgroundColor = .clear
        edgesForExtendedLayout = .all
        view.addSubview(backgroundScrollView)
        NSLayoutConstraint.activate([
            backgroundScrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            backgroundScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -44),
            backgroundScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        addBackgroundImages()
        
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -23)
        ])
        
        configureTitleLabel()
    }
    
    
    private func configureTitleLabel() {
        let text = "Hunt Through\n100K+ Movies."
        let attributedString = NSMutableAttributedString(string: text)
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.lineSpacing = -10
        paragraphStyle.minimumLineHeight = 54
        paragraphStyle.maximumLineHeight = 54
        paragraphStyle.alignment = .left
        
        // Apply white color for all text.
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: text.count))
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: text.count))
        
        let purpleColor = UIColor(red: 0.74, green: 0.35, blue: 0.89, alpha: 1.0)
        attributedString.addAttribute(.foregroundColor, value: purpleColor, range: NSRange(location: 0, length: text.count))
        
        
        titleLabel.baselineAdjustment = .alignBaselines
        titleLabel.clipsToBounds = false
        titleLabel.attributedText = attributedString
    }
    
    
    
    private func addBackgroundImages() {
        let movieCovers = ["1", "2", "3", "4", "5", "6", "7"]
        
        let cardWidth: CGFloat = 200
        let cardHeight: CGFloat = 400
        
        let horizontalSpacing: CGFloat = 16
        
        let verticalPadding: CGFloat = 16
        
        var previousImageView: UIImageView?
        
        for cover in movieCovers {
            let imageView = UIImageView(image: UIImage(named: cover))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            
            // Corner radius
            imageView.layer.cornerRadius = Constants.CornerRaduce.imageRaduce
            imageView.layer.masksToBounds = true
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            backgroundScrollView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerYAnchor.constraint(equalTo: backgroundScrollView.centerYAnchor, constant: 120),
                
                imageView.widthAnchor.constraint(equalToConstant: cardWidth),
                imageView.heightAnchor.constraint(equalToConstant: cardHeight)
            ])
            
            if let previous = previousImageView {
                imageView.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: horizontalSpacing).isActive = true
            } else {
                imageView.leadingAnchor.constraint(equalTo: backgroundScrollView.leadingAnchor, constant: horizontalSpacing).isActive = true
            }
            
            previousImageView = imageView
        }
        
        previousImageView?.trailingAnchor.constraint(
            equalTo: backgroundScrollView.trailingAnchor,
            constant: -horizontalSpacing
        ).isActive = true
        
        let totalWidth = (cardWidth + horizontalSpacing) * CGFloat(movieCovers.count)
        + horizontalSpacing
        backgroundScrollView.contentSize = CGSize(
            width: totalWidth,
            height: cardHeight + 2 * verticalPadding
        )
    }
    
    
    
    private func startBackgroundScrolling() {
        let totalWidth = backgroundScrollView.contentSize.width
        if totalWidth <= view.frame.width { return }
        
        let scrollSpeed: CGFloat = 30.0
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
    
    
}
