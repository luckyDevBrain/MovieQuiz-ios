//
//  StatisticService.swift
//  MovieQuiz
//
//  Created by Kirill on 31.05.2024.
//

import Foundation

final class StatisticService: StatisticServiceProtocol {
    private let storage: UserDefaults = .standard
    
    private enum Keys {
        static let gamesCount = "gamesCount"
        static let bestGameCorrect = "bestGameCorrect"
        static let bestGameTotal = "bestGameTotal"
        static let bestGameDate = "bestGameDate"
        static let totalCorrect = "totalCorrect"
        static let totalQuestions = "totalQuestions"
    }
    
    var gamesCount: Int {
        get {
            return storage.integer(forKey: Keys.gamesCount)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount)
        }
    }
    
    var bestGame: GameResult {
        get {
            let correct = storage.integer(forKey: Keys.bestGameCorrect)
            let total = storage.integer(forKey: Keys.bestGameTotal)
            let date = storage.object(forKey: Keys.bestGameDate) as? Date ?? Date()
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: Keys.bestGameCorrect)
            storage.set(newValue.total, forKey: Keys.bestGameTotal)
            storage.set(newValue.date, forKey: Keys.bestGameDate)
        }
    }
    
    var totalAccuracy: Double {
        let totalCorrect = storage.integer(forKey: Keys.totalCorrect)
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions)
        guard totalQuestions != 0 else { return 0.0 }
        return Double(totalCorrect) / Double(totalQuestions) * 100.0
    }
    
    func store(correct count: Int, total amount: Int) {
        gamesCount += 1
        
        let newResult = GameResult(correct: count, total: amount, date: Date())
        if newResult.isBetterThan(bestGame) {
            bestGame = newResult
        }
        
        let totalCorrect = storage.integer(forKey: Keys.totalCorrect) + count
        let totalQuestions = storage.integer(forKey: Keys.totalQuestions) + amount
        storage.set(totalCorrect, forKey: Keys.totalCorrect)
        storage.set(totalQuestions, forKey: Keys.totalQuestions)
    }
}
