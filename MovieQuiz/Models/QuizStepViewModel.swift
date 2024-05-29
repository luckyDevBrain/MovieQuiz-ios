//
//  QuizStepViewModel.swift
//  MovieQuiz
//
//  Created by Kirill on 28.05.2024.
//

import UIKit

// MARK: - ViewModel для состояния "Вопрос показан"
struct QuizStepViewModel {
    let image: UIImage          // картинка с афишей фильма
    let question: String        // вопрос о рейтинге квиза
    let questionNumber: String  // порядковый номер вопроса (ex. "1/10")
}
