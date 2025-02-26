//
//  MovieViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//

import UIKit
import Combine
import Kingfisher

// MARK: - MovieViewController
class MovieViewController: UIViewController {
    
    private var collectionView: UICollectionView!
    private let viewModel = MovieViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var hasSearched = false
    private var searchSubject = PassthroughSubject<String, Never>()
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
    
    
    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.delegate = self
        sb.placeholder = "Search Movies"
        
        let searchTextField = sb.searchTextField
        searchTextField.textColor = .systemBackground
        searchTextField.leftView?.tintColor = .white
        searchTextField.backgroundColor = .lightGray
        searchTextField.tintColor = UIColor.label
        sb.barTintColor = .lightGray
        sb.tintColor = .black
        
        return sb
    }()
    
    private let emptyViewLabel: UILabel = {
        let label = UILabel()
        label.text = "No results found"
        label.textColor = .darkGray
        label.textAlignment = .center
        label.font = .CDFontMedium(size: 18)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupSearchBinding()
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
        
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseIdentifier)
        collectionView.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
        ])
        
        view.addSubview(emptyViewLabel)
        NSLayoutConstraint.activate([
            emptyViewLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyViewLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        
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
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        
        let isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        let itemWidthFraction: CGFloat = isLandscape ? 0.3 : 0.45  // Smaller width in landscape for more items
        
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidthFraction),
            heightDimension: .estimated(320)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
            leading: .fixed(8),
            top: .fixed(8),
            trailing: .fixed(8),
            bottom: .fixed(8)
        )
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(320)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
    private func bindViewModel() {
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                guard let self = self else { return }
                
                if !hasSearched {
                    // Show initial empty state before search starts
                    emptyViewLabel.text = "Start searching for movies"
                    emptyViewLabel.isHidden = false
                } else {
                    // Show no results only if search was performed
                    emptyViewLabel.text = movies.isEmpty ? "No results found" : ""
                    emptyViewLabel.isHidden = !movies.isEmpty
                }
                
                collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    
    private func setupSearchBinding() {
        searchSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // Delay to avoid frequent requests
            .filter { $0.count >= 3 }
            .sink { [weak self] query in
                guard let self = self else { return }
                self.hasSearched = true
                self.viewModel.searchMovies(query: query)
            }
            .store(in: &cancellables)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout = createLayout()  // Update layout on orientation change
    }
    
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension MovieViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCell.reuseIdentifier, for: indexPath) as? MovieCell else {
            return UICollectionViewCell()
        }
        let movie = viewModel.movies[indexPath.item]
        cell.configure(with: movie)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.item]
        viewModel.loadMoreIfNeeded(currentItem: movie)
    }
}

extension MovieViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}


extension MovieViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        hasSearched = true
        viewModel.searchMovies(query: query)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchSubject.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hasSearched = false
        viewModel.clearMovies() // Assuming you have this method to reset
        collectionView.reloadData()
    }
}

//
//// MARK: - UISearchBarDelegate
//extension MovieViewController: UISearchBarDelegate {
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        guard let query = searchBar.text, !query.isEmpty else { return }
//        viewModel.searchMovies(query: query)
//        searchBar.resignFirstResponder()
//    }
//
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        searchSubject.send(searchText)
//    }
//
//}

// MARK: - MovieCell

import UIKit
import Combine

class MovieCell: UICollectionViewCell {
    static let reuseIdentifier = "MovieCell"
    private var movie: Movie?
    private var cancellables = Set<AnyCancellable>()
    
    // Card container view
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.layer.cornerRadius = 15.64
        view.layer.borderWidth = 0.47
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
        label.layer.borderWidth = 0.5
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
        label.textColor = UIColor.gray
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
            yearLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -8),
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
         movie?.isLiked.toggle()  // Update state via Combine
     }
    
}

