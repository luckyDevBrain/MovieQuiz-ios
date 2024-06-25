//
//  MovieQuizViewControllerProtocol.swift
//  MovieQuiz
//
//  Created by Kirill on 25.06.2024.
//

import UIKit
import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    var questionTitleLabel: UILabel! { get set }
    func setupButtons()
    
    func show(quiz step: QuizStepViewModel)
    func show(quiz result: QuizResultsViewModel)
    
    func resetImageBorder()
    func updateImageBorder(isCorrectAnswer: Bool)
    
    func showLoadingIndicator()
    func hideLoadingIndicator()
    
    func presentAlert(with model: AlertModel)
    
    func showNetworkError(message: String)
    
    func enableButtons()
    func disableButtons()
}
