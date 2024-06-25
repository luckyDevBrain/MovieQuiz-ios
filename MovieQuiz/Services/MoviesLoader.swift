//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Kirill on 11.06.2024.
//

import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    // MARK: - NetworkClient
    private let networkClient: NetworkRouting
    
    init(networkClient: NetworkRouting = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // MARK: - URL
    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf") else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .success(let data):
                do {
                    let mostPopularMovies = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    handler(.success(mostPopularMovies))
                } catch {
                    handler(.failure(error))
                }
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    self.handleNetworkError(networkError, handler: handler)
                } else {
                    handler(.failure(error))
                }
            }
        }
    }
    
    private func handleNetworkError(_ error: NetworkError, handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        // Обработка ошибок сети и вызов обработчика с ошибкой
        let errorMessage: String
        switch error {
        case .codeError(let statusCode):
            errorMessage = "Ошибка HTTP с кодом \(statusCode)"
        case .invalidAPIKey(let message):
            errorMessage = "Неверный API ключ: \(message)"
        case .loadImageError(let message):
            errorMessage = "Ошибка загрузки изображения: \(message)"
        case .unexpectedResponse:
            errorMessage = "Неожиданный ответ сервера"
        case .customError(let message):
            errorMessage = message
        }
        handler(.failure(NetworkError.customError(errorMessage)))
    }
}
