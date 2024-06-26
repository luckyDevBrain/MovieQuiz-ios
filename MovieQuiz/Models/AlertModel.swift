//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Kirill on 30.05.2024.
//

import Foundation

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}
