//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Kirill on 11.06.2024.
//

import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, NetworkClient.NetworkErrors>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    // MARK: - NetworkClient
    private let networkClient = NetworkClient()
    
    // MARK: - URL
    private var mostPopularMoviesUrl: URL {
        // Если мы не смогли преобразовать строку в URL, то приложение упадёт с ошибкой
        guard let url = URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf") else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }
    
    func loadMovies(handler: @escaping (Result<MostPopularMovies, NetworkClient.NetworkErrors>) -> Void) {
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .success(let data):
                do {
                    let mostPopularMovies = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    if !mostPopularMovies.errorMessage.isEmpty {
                        handler(.failure(.invalidAPIKey(mostPopularMovies.errorMessage)))
                    } else {
                        handler(.success(mostPopularMovies))
                    }
                } catch {
                    // Обработка ошибки декодирования
                    handler(.failure(.codeError(0)))
                }
            case .failure(let error):
                // Передача ошибки от NetworkClient
                let networkError = networkClient.handleNetworkError(error)
                handler(.failure(networkError))
            }
        }
    }
}
