//
//  MovieCell.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-25.
//





// MARK: - MovieCell

import UIKit
import Combine

class MovieCell: UICollectionViewCell {
    static let reuseIdentifier = "MovieCell"
    private var movie: Movie?
    private var cancellables = Set<AnyCancellable>()
    var onLikeButtonUpdate: (() -> Void)?
    
    // Card container view
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "CardBackground") ?? .systemBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor =  UIColor(red: 0.327, green: 0.323, blue: 0.323, alpha: 1).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Image container with rounded corners
    private let imageContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10.42
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Movie image view
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Favourite label
    private let favouriteLabel: UILabel = {
        let label = UILabel()
        label.text = "FAVOURITE"
        label.font = .CDFontSemiBold(size: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 0.93, green: 0, blue: 1, alpha: 1)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1.0
        label.layer.borderColor = UIColor.white.cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    
    // Movie title
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .CDFontSemiBold(size: 16)
        label.numberOfLines = 2
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Year label
    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = .CDFontSemiBold(size: 16)
        label.textColor = UIColor(named: "HFSecoundaryLabel") ?? .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Action button
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "like")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        contentView.addSubview(cardView)
        cardView.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        imageContainerView.addSubview(favouriteLabel)
        cardView.addSubview(titleLabel)
        cardView.addSubview(yearLabel)
        cardView.addSubview(actionButton)
        
        // Card view constraints
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Image container constraints
        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            imageContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            imageContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
        ])
        
        let imageHeightConstraint = imageContainerView.heightAnchor.constraint(equalToConstant: 260.0)
        imageHeightConstraint.priority = .defaultHigh
        imageHeightConstraint.isActive = true
        
        // Image view constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor)
        ])
        
        // Favourite label constraints
        NSLayoutConstraint.activate([
            favouriteLabel.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: -7),
            favouriteLabel.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor, constant: 8),
            favouriteLabel.heightAnchor.constraint(equalToConstant: 22),
            favouriteLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        
        // Title and Year labels
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            titleLabel.heightAnchor.constraint(equalToConstant: 80),
            
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            yearLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            yearLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            yearLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -16),
        ])
        
        
        // Action button constraints
        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            actionButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            actionButton.widthAnchor.constraint(equalToConstant: 24),
            actionButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
    }
    
    // MARK: - Configure Cell
    func configure(with movie: Movie) {
        cancellables.removeAll()
        self.movie = movie

        titleLabel.text = movie.title
        yearLabel.text = movie.year
        loadImage(for: movie.poster)

        // Subscribe to isLiked changes
        movie.$isLiked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLiked in
                guard let self = self else { return }
                self.updateUI(for: isLiked)
            }
            .store(in: &cancellables)

        // Set initial UI state
        updateUI(for: movie.isLiked)
    }
    
    private func updateUI(for isLiked: Bool) {
        favouriteLabel.isHidden = !isLiked
        cardView.layer.borderColor = isLiked
            ? UIColor(red: 0.93, green: 0, blue: 1, alpha: 1).cgColor
            : UIColor(red: 0.327, green: 0.323, blue: 0.323, alpha: 1).cgColor
        let imageName = isLiked ? "liked" : "like"
        actionButton.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
    }
    
    private func loadImage(for url: String) {
        guard let url = URL(string: url) else { return }
        imageView.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
    }
    
    @objc private func buttonTapped() {
         movie?.isLiked.toggle()
         onLikeButtonUpdate?()
     }
}
