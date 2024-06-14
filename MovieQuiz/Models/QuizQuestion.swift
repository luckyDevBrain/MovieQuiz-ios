//
//  QuizQuestion.swift
//  MovieQuiz
//
//  Created by Kirill on 28.05.2024.
//

import Foundation

// MARK: - ViewModel для "Вопроса квиза"
struct QuizQuestion {
    let image: Data
    let text: String
    let correctAnswer: Bool
}

/*
struct QuizQuestion {
    let image: String        // изображение фильма
    let text: String         // вопрос о рейтинге фильма
    let correctAnswer: Bool  // правильный ответ на вопрос
}
*/

