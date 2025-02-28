//
//  SearchChildViewController.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//

import UIKit
import Combine
import Kingfisher

protocol SearchChildDelegate: AnyObject {
    func dismissKeyboard()
}

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
    weak var delegate: SearchChildDelegate?
    
    
    
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
        definesPresentationContext = true        
        let layout = createLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: MovieCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
        ])
        
        view.backgroundColor = .clear
        view.addSubview(emptyViewLabel)
        NSLayoutConstraint.activate([
            emptyViewLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyViewLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        
    }
    
    private func createLayout() -> UICollectionViewCompositionalLayout {
        
        let isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        let itemWidthFraction: CGFloat = isLandscape ? 0.3 : 0.45
        
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
        
        viewModel.$errorMessage
                .compactMap { $0 }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] errorMessage in
                    guard let self = self else { return }
                    self.showErrorAlert(message: errorMessage)
                }
                .store(in: &cancellables)
    }
    
    
    private func applyMoviesSnapshot(movies: [Movie]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Movie>()
        snapshot.appendSections([.main])
        snapshot.appendItems(movies, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func updateSearchQuery(_ text: String) {
        searchSubject.send(text)
    }
    
    func clearSearch() {
        hasSearched = false
        emptyViewLabel.text = "Start searching for movies"
        emptyViewLabel.isHidden = false
        viewModel.clearSearch()
    }
    
    
    
    
    
    private func setupSearchBinding() {
        searchSubject
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                if text.count < 3 {
                    self.hasSearched = false
                    self.emptyViewLabel.text = "Start searching for movies"
                    self.emptyViewLabel.isHidden = false
                    self.viewModel.clearSearch()
                } else {
                    self.hasSearched = true
                    self.viewModel.searchMovies(query: text)
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout = createLayout()
    }
    
    func reconfigure(movie: Movie) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems([movie])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Opps", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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

extension SearchChildViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.dismissKeyboard()
    }
}

