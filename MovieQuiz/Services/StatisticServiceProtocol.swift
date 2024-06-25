//
//  StatisticServiceProtocol.swift
//  MovieQuiz
//
//  Created by Kirill on 31.05.2024.
//

import Foundation

protocol StatisticServiceProtocol {
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
    var totalAccuracy: Double { get }
    
    func store(correct count: Int, total amount: Int)
}
