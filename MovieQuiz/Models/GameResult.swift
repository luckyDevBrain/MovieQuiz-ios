//
//  GameResult.swift
//  MovieQuiz
//
//  Created by Kirill on 31.05.2024.
//

import Foundation

struct GameRecord: Codable {
    let correct: Int
    let total: Int
    let date: Date

    /// метод сравнения по количеству верных ответов
    func isBetterThan(_ another: GameRecord) -> Bool {
        correct > another.correct
    }
}
