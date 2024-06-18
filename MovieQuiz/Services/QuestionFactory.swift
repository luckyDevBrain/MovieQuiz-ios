//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Kirill on 28.05.2024.
//

import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    private var movies: [MostPopularMovie] = []
    
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    if !mostPopularMovies.errorMessage.isEmpty {
                        self.delegate?.didFailToLoadData(with: .invalidAPIKey(mostPopularMovies.errorMessage))
                    } else {
                        self.movies = mostPopularMovies.items
                        self.delegate?.didLoadDataFromServer()
                    }
                case .failure(let error):
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    func requestNextQuestion() {
        delegate?.willLoadNextQuestion() // Уведомление делегата перед началом загрузки
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            guard let movie = self.movies[safe: index] else { return }
            
            self.loadImage(for: movie) { result in
                        switch result {
                        case .success(let imageData):
                            // Создание вопроса и уведомление делегата
            
            let ratingThreshold = Float.random(in: 5.0...9.0)
            let ratingThresholdString = String(format: "%.1f", ratingThreshold)
            
            let movieRating = Float(movie.rating) ?? 0
            let movieRatingString = String(format: "%.1f", movieRating)
            
            let text = "Рейтинг этого фильма больше, чем \(ratingThresholdString)?"
            let correctAnswer = (Float(movieRatingString) ?? 0) > (Float(ratingThresholdString) ?? 0)
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
                            DispatchQueue.main.async {
                                                self.delegate?.didReceiveNextQuestion(question: question)
                                            }
                                        case .failure(let error):
                                            DispatchQueue.main.async {
                                                self.delegate?.didFailLoadingImage(with: error) // Уведомление делегата об ошибке
                                            }
                                        }
                                    }
                                }
                            }
    
    private func loadImage(for movie: MostPopularMovie, completion: @escaping (Result<Data, NetworkClient.NetworkErrors>) -> Void) {
        DispatchQueue.global().async {
            do {
                let imageData = try Data(contentsOf: movie.resizedImageURL)
                DispatchQueue.main.async {
                    completion(.success(imageData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.loadImageError(error.localizedDescription)))
                }
            }
        }
    }
}
