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
    private let movieService: MovieService

    private var currentPage = 1
    private var currentQuery = ""
    private var cancellables = Set<AnyCancellable>()
    private let apiKey = Constants.AppConfig.apiKey
    
    
    init(movieService: MovieService = .shared) {
        self.movieService = movieService
    }

    // Search movies with pagination
    func searchMovies(query: String, reset: Bool = true) {
        guard !query.isEmpty else {
            errorMessage = "Invalid query."
            return
        }

        if reset {
            currentPage = 1
            currentQuery = query
            movies.removeAll()
        }

        isLoading = true

        movieService.searchMovies(query: query, page: currentPage)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load movies: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] movies in
                self?.movies.append(contentsOf: movies)
                self?.currentPage += 1
            })
            .store(in: &cancellables)
    }


    // Load more results when reaching the end
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
    }
    
    func clearMovies() {
          self.movies = []
      }
}
