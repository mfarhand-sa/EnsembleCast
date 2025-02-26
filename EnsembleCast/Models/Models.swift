//
//  Movie.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-24.
//


import Foundation
import Combine

// MARK: - Movie Model
class Movie: ObservableObject, Identifiable, Codable {
    let id: String
    let title: String
    let year: String
    let poster: String
    
    @Published var isLiked: Bool = false  // Combine-backed property

    enum CodingKeys: String, CodingKey {
        case id = "imdbID"
        case title = "Title"
        case year = "Year"
        case poster = "Poster"
    }
    
    init(id: String, title: String, year: String, poster: String, isLiked: Bool = false) {
        self.id = id
        self.title = title
        self.year = year
        self.poster = poster
        self.isLiked = isLiked
    }
    
    // Custom decoding to initialize ObservableObject
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        year = try container.decode(String.self, forKey: .year)
        poster = try container.decode(String.self, forKey: .poster)
        isLiked = false  // Default value, not from API
    }
    
    // Custom encoding to exclude isLiked from API payloads
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(year, forKey: .year)
        try container.encode(poster, forKey: .poster)
    }
}

// MARK: - Movie Response
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
