//
//  MovieViewModel.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-25.
//

import Foundation
import Combine

// MARK: - MovieViewModel
class MovieViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    private var isFetching: Bool = false
    private let movieService: MovieService
    
    private var currentPage = 1
    private var currentQuery = ""
    private var cancellables = Set<AnyCancellable>()
    
    
    init(movieService: MovieService = .shared) {
        self.movieService = movieService
    }
    
    // Search movies with pagination
    func searchMovies(query: String, reset: Bool = true) {
        guard !query.isEmpty else {
            errorMessage = "Invalid query."
            return
        }
        guard !isLoading else { return }
        
        if reset {
            currentPage = 1
            currentQuery = query
            movies.removeAll()
        }
        
        isLoading = true
        
        movieService.searchMovies(query: query, page: currentPage)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = "Failed to load movies: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] movies in
                guard let self = self else { return }
                self.movies.append(contentsOf: movies)
                self.currentPage += 1
            })
            .store(in: &cancellables)
    }
    
    
    func loadMoreIfNeeded(currentItem: Movie) {
        guard let lastItem = movies.last, lastItem.id == currentItem.id else { return }
        searchMovies(query: currentQuery, reset: false)
    }
    
    // Clear search results
    func clearSearch() {
        movies.removeAll()
        currentPage = 1
        currentQuery = ""
        errorMessage = nil
        isLoading = false
    }
}
