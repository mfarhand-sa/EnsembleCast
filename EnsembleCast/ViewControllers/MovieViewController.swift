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
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
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
        if !searchController.isActive {
            searchController.isActive = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
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
class MovieCell: UICollectionViewCell {
    static let reuseIdentifier = "MovieCell"
    
    // Add a container view for the card
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    
    private let imageContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true  // Ensure corners are clipped
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.numberOfLines = 2
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let yearLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "like")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let actionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemPink
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        contentView.addSubview(cardView)
        cardView.addSubview(imageContainerView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        imageContainerView.addSubview(imageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(yearLabel)
        cardView.addSubview(actionButton)
        cardView.addSubview(actionLabel)
        
        
        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imageContainerView.heightAnchor.constraint(equalToConstant: 200),

            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
  
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            yearLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            yearLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            
            actionButton.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 4),
            actionButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            
            actionLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 4),
            actionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            actionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with movie: Movie) {
        titleLabel.text = movie.title
        yearLabel.text = "Year: \(movie.year)"
        actionLabel.text = "saved"
        loadImage(for: movie.poster)
    }
    
    private func loadImage(for url: String) {
        guard let url = URL(string: url) else {
            return
        }
        
        imageView.kf.setImage(
            with: url,
            options: [],
            completionHandler: { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(_): break
                case .failure(_):
                    self.imageView.image = UIImage(named: "placeholder")
                    break
                }
            }
        )
    }
    
    @objc private func buttonTapped() {
        actionLabel.isHidden.toggle()
        updateCellHeight()
    }
    
    private func updateCellHeight() {
        UIView.animate(withDuration: 0.3) {
            self.superview?.layoutIfNeeded()
        }
    }
}
