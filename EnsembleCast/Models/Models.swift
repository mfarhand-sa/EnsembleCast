//
//  Movie.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//


// MARK: - Movie Model
struct Movie: Codable, Identifiable {
    let id: String
    let title: String
    let year: String
    let poster: String

    enum CodingKeys: String, CodingKey {
        case id = "imdbID"
        case title = "Title"
        case year = "Year"
        case poster = "Poster"
    }
}

struct MovieResponse: Codable {
    let search: [Movie]?
    let totalResults: String?
    let response: String

    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}