//
//  MovieQuizPresenter.swift
//  MovieQuiz
//
//  Created by Kirill on 23.06.2024.
//

import Foundation
import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    
    private let statisticService: StatisticServiceProtocol!
    private var questionFactory: QuestionFactoryProtocol?
    private weak var viewController: MovieQuizViewControllerProtocol?
    private var alertPresenter: AlertPresenter?
    
    private var currentQuestion: QuizQuestion?
    private let questionsAmount: Int = 10 // общее количество вопросов
    private var currentQuestionIndex: Int = 0 // индекс текущего вопроса
    private var correctAnswers: Int = 0 // счетчик правильных ответов
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController
        self.alertPresenter = AlertPresenter(viewController: viewController as! UIViewController)
        
        statisticService = StatisticService()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didLoadDataFromServer() {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.hideLoadingIndicator()
            self?.questionFactory?.requestNextQuestion()
        }
    }
    
    func didFailToLoadData(with error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.hideLoadingIndicator()
            let alertModel = AlertModel(
                title: "Ошибка загрузки",
                message: error.localizedDescription,
                buttonText: "OK",
                completion: { [weak self] in
                    self?.questionFactory?.loadData() // Попытка перезагрузить данные
                }
            )
            self?.alertPresenter?.presentAlert(with: alertModel) // Используем AlertPresenter для показа алерта
        }
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        self.viewController?.hideLoadingIndicator()
        guard let question = question else {
            self.viewController?.showNetworkError(message: "Произошла ошибка при загрузке вопроса.")
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.show(quiz: viewModel)
            self?.viewController?.enableButtons()
            self?.viewController?.questionTitleLabel.text = "Вопрос:"
        }
    }
    
    func willLoadNextQuestion() {
        self.viewController?.showLoadingIndicator() // Показывваем индикатор загрузки
    }
    
    func didFailLoadingImage(with error: Error) {
        self.viewController?.hideLoadingIndicator()
        let errorMessage: String
        switch error {
        case NetworkError.codeError(let statusCode):
            errorMessage = "Ошибка HTTP с кодом \(statusCode)"
        case NetworkError.invalidAPIKey(let message):
            errorMessage = "Неверный API ключ: \(message)"
        case NetworkError.loadImageError(let message):
            errorMessage = "Ошибка загрузки изображения: \(message)"
        case NetworkError.unexpectedResponse:
            errorMessage = "Неожиданный ответ сервера"
        default:
            errorMessage = error.localizedDescription
        }
        
        let alertModel = AlertModel(
            title: "Ошибка",
            message: errorMessage,
            buttonText: "Попробовать еще раз",
            completion: { [weak self] in
                self?.questionFactory?.loadData() // Попытка перезагрузить данные
            }
        )
        self.alertPresenter?.presentAlert(with: alertModel) // Используем AlertPresenter для показа алерта
    }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func didAnswer(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            correctAnswers += 1
        }
    }
    
    func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    // MARK: - Actions
    func yesButtonClicked() {
        didAnswer(isYes: true)
    }
    
    func noButtonClicked() {
        didAnswer(isYes: false)
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        
        proceedWithAnswer(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func proceedWithAnswer(isCorrect: Bool) {
        didAnswer(isCorrectAnswer: isCorrect)
        viewController?.questionTitleLabel.text = isCorrect ? "Верно!" : "Неверно!"
        viewController?.updateImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.proceedToNextQuestionOrResults()
        }
    }
    
    private func proceedToNextQuestionOrResults() {
        if self.isLastQuestion() {
            // Сохраняем статистику игры перед созданием сообщения с результатами
            storeGameStatistics()
            
            let text = "Вы ответили на \(correctAnswers) из 10, попробуйте ещё раз!"
            
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            viewController?.show(quiz: viewModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func storeGameStatistics() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
    }
    
    func makeResultsMessage() -> String {
        let bestGame = statisticService.bestGame
        
        return """
            Количество сыгранных квизов: \(statisticService.gamesCount)
            Ваш результат: \(correctAnswers)/\(questionsAmount)
            Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
            Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
            """
    }
}
