//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Kirill on 30.05.2024.
//

import Foundation

protocol QuestionFactoryDelegate: AnyObject {
    func didLoadDataFromServer() // сообщение об успешной загрузке
    func didFailToLoadData(with error: NetworkClient.NetworkErrors) // сообщение об ошибке загрузки
    func willLoadNextQuestion()
    func didFailLoadingImage(with error: NetworkClient.NetworkErrors)
    func didReceiveNextQuestion(question: QuizQuestion?)
}
