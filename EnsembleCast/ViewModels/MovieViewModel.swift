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

    private var currentPage = 1
    private var currentQuery = ""
    private var cancellables = Set<AnyCancellable>()
    private let apiKey = Constants.AppConfig.apiKey

    // Search movies with pagination
    func searchMovies(query: String, reset: Bool = true) {
        guard !query.isEmpty, !apiKey.isEmpty else {
            errorMessage = "Invalid API key or query."
            return
        }

        if reset {
            currentPage = 1
            currentQuery = query
            movies.removeAll()
        }

        isLoading = true
        let urlString = "https://www.omdbapi.com/?s=\(query)&page=\(currentPage)&apikey=\(apiKey)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: MovieResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to load movies: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] response in
                guard let self = self, response.response == "True" else {
                    self?.errorMessage = "No results found."
                    return
                }
                
                // Safely unwrap optional search results
                if let movies = response.search {
                    self.movies.append(contentsOf: movies)
                    self.currentPage += 1
                } else {
                    self.errorMessage = "No movies found for this search."
                }
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
