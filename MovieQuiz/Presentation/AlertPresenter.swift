//
//  AlertPresenter.swift
//  MovieQuiz
//
//  Created by Kirill on 30.05.2024.
//

import UIKit

class AlertPresenter {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func presentAlert(with model: AlertModel) {
        let alert = UIAlertController(title: model.title, message: model.message, preferredStyle: .alert)
        let action = UIAlertAction(title: model.buttonText, style: .default) { _ in
            model.completion()
        }
        alert.addAction(action)
        viewController?.present(alert, animated: true, completion: nil)
    }
}
