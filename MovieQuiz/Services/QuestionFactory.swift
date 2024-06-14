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
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let index = (0..<self.movies.count).randomElement() ?? 0
            
            guard let movie = self.movies[safe: index] else { return }
            
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                print("Failed to load image")
            }
            
            let ratingThreshold = Float.random(in: 5.0...9.0)
            let ratingThresholdString = String(format: "%.1f", ratingThreshold)
            
            let movieRating = Float(movie.rating) ?? 0
            let movieRatingString = String(format: "%.1f", movieRating)
            
            let text = "Рейтинг этого фильма больше, чем \(ratingThresholdString)?"
            let correctAnswer = (Float(movieRatingString) ?? 0) > (Float(ratingThresholdString) ?? 0)
            
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
    
    private func loadImage(for movie: MostPopularMovie, completion: @escaping (Data) -> Void) {
        DispatchQueue.global().async {
            var imageData = Data()
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                print("Failed to load image")
            }
            completion(imageData)
        }
    }
}

// массив как переменная с mock-данными
/*
 private let questions: [QuizQuestion] = [
 QuizQuestion(
 image: "The Godfather",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: true),
 QuizQuestion(
 image: "The Dark Knight",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: true),
 QuizQuestion(
 image: "Kill Bill",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: true),
 QuizQuestion(
 image: "The Avengers",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: true),
 QuizQuestion(
 image: "Deadpool",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: true),
 QuizQuestion(
 image: "The Green Knight",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: true),
 QuizQuestion(
 image: "Old",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: false),
 QuizQuestion(
 image: "The Ice Age Adventures of Buck Wild",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: false),
 QuizQuestion(
 image: "Tesla",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: false),
 QuizQuestion(
 image: "Vivarium",
 text: "Рейтинг этого фильма\nбольше чем 6?",
 correctAnswer: false)
 ]
 */

/*
 func setup(delegate: QuestionFactoryDelegate) {
 self.delegate = delegate
 }
 
 func requestNextQuestion() {
 guard let index = (0..<questions.count).randomElement() else {
 delegate?.didReceiveNextQuestion(question: nil)
 return
 }
 
 let question = questions[safe: index]
 delegate?.didReceiveNextQuestion(question: question)
 }
 */
