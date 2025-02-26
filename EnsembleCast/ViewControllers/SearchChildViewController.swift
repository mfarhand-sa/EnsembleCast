//
//  SearchChildViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//

import UIKit
import Combine
import Kingfisher

// MARK: - SearchChildViewController


class SearchChildViewController: UIViewController {
    
    private let homeContainerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Movie>!
    private var collectionView: UICollectionView!
    private let viewModel = MovieViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var hasSearched = false
    private var searchSubject = PassthroughSubject<String, Never>()


    
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
        setupDataSource()
        
        var initialSnapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        initialSnapshot.appendSections([.main])
        initialSnapshot.appendItems(viewModel.movies, toSection: .main)
        dataSource.apply(initialSnapshot, animatingDifferences: false)

        
        bindViewModel()
        setupSearchBinding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Movie>(
            collectionView: collectionView
        ) { (collectionView, indexPath, movie) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieCell.reuseIdentifier,
                for: indexPath
            ) as? MovieCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: movie)
            cell.onLikeButtonUpdate  = { [weak self] in
                guard let self = self else { return }
                self.reconfigure(movie: movie)
            }
            return cell
        }
    }
    

    
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
       // setupNavigation()
        // Add search controller to the navigation bar
        definesPresentationContext = true
        
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
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
        section.interGroupSpacing = 5
        section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
    private func bindViewModel() {
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                guard let self = self else { return }
                
                if !self.hasSearched {
                    self.emptyViewLabel.text = "Start searching for movies"
                    self.emptyViewLabel.isHidden = false
                } else {
                    self.emptyViewLabel.text = movies.isEmpty ? "No results found" : ""
                    self.emptyViewLabel.isHidden = !movies.isEmpty
                }
                
                self.applyMoviesSnapshot(movies: movies)
            }
            .store(in: &cancellables)
    }

    
    private func applyMoviesSnapshot(movies: [Movie]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        snapshot.appendSections([.main])
        snapshot.appendItems(movies, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updateSearchQuery(_ text: String) {
        if text.count < 3 {
            hasSearched = false
            // Optionally show "Start searching..." right away:
            emptyViewLabel.text = "Start searching for movies"
            emptyViewLabel.isHidden = false
            
            // Clear old results so the collection goes empty
            viewModel.clearSearch()
        } else {
            hasSearched = true
            // Do the actual search
            viewModel.searchMovies(query: text)
        }
    }

    func clearSearch() {
        hasSearched = false
        // Also show the same "Start searching" message if you like:
        emptyViewLabel.text = "Start searching for movies"
        emptyViewLabel.isHidden = false
        
        viewModel.clearSearch()
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
    
    func reconfigure(movie: Movie) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([movie])  // reconfigure exactly one item
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension SearchChildViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item < viewModel.movies.count else { return }
        let movie = viewModel.movies[indexPath.item]
        viewModel.loadMoreIfNeeded(currentItem: movie)
    }
}

