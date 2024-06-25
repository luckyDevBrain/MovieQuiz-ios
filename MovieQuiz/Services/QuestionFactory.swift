//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Kirill on 28.05.2024.
//

import Foundation

// Определение пользовательских ошибок, связанных с фабрикой вопросов
enum QuestionFactoryError: Error {
    case invalidAPIKey(String) // Ошибка неверного API ключа
    case loadImageError(String) // Ошибка загрузки изображения
}

// Класс QuestionFactory отвечает за создание вопросов для викторины
final class QuestionFactory: QuestionFactoryProtocol {
    
    // Свойства для работы с загрузчиком фильмов и делегатом
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?
    private var movies: [MostPopularMovie] = [] // Список популярных фильмов
    
    // Инициализатор с зависимостями
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }
    
    // Метод для загрузки данных о фильмах
    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let mostPopularMovies):
                    // Проверка на наличие сообщения об ошибке
                    if !mostPopularMovies.errorMessage.isEmpty {
                        // Уведомление делегата об ошибке
                        self.delegate?.didFailToLoadData(with: QuestionFactoryError.invalidAPIKey(mostPopularMovies.errorMessage))
                    } else {
                        // Сохранение полученных фильмов и уведомление делегата
                        self.movies = mostPopularMovies.items
                        self.delegate?.didLoadDataFromServer()
                    }
                case .failure(let error):
                    // Уведомление делегата о любой ошибке загрузки
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }
    
    func requestNextQuestion() {
        delegate?.willLoadNextQuestion() // Уведомление делегата о начале загрузки
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            guard !self.movies.isEmpty else {
                // Если список фильмов пуст, уведомляем делегата об ошибке
                DispatchQueue.main.async {
                    self.delegate?.didFailToLoadData(with: QuestionFactoryError.invalidAPIKey("Нет доступных фильмов"))
                }
                return
            }
            
            // Выбор случайного фильма из списка
            let index = (0..<self.movies.count).randomElement() ?? 0
            guard let movie = self.movies[safe: index] else { return }
            
            // Загрузка изображения для выбранного фильма
            self.loadImage(for: movie) { result in
                DispatchQueue.main.async {
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
                        
                        
                        self.delegate?.didReceiveNextQuestion(question: question)
                    case .failure(let error):
                        // Уведомление делегата об ошибке загрузки изображения
                        self.delegate?.didFailLoadingImage(with: error)
                    }
                }
            }
        }
    }
    
    private func loadImage(for movie: MostPopularMovie, completion: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                let imageData = try Data(contentsOf: movie.resizedImageURL)
                DispatchQueue.main.async {
                    completion(.success(imageData))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(QuestionFactoryError.loadImageError(error.localizedDescription)))
                }
            }
        }
    }
}
