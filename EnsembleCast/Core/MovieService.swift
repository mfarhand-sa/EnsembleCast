//
//  MovieService.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//


import Foundation
import Combine

// MARK: - API Service
class MovieService {
    static let shared = MovieService()
    private var cancellables = Set<AnyCancellable>()
    
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        guard let url = URL(string: "\(Constants.AppConfig.baseURL)?s=\(query)&page=\(page)&apikey=\(Constants.AppConfig.apiKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: MovieResponse.self, decoder: JSONDecoder())
            .map { $0.search ?? [] }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
