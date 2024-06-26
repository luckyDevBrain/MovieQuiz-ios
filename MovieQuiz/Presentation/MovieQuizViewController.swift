import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate  {
    
    func didLoadDataFromServer() {
        showLoadingIndicator() // Показывваем индикатор загрузки
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: NetworkClient.NetworkErrors) {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingIndicator()
            let errorCompletion = {
                self?.currentQuestionIndex = 0
                self?.correctAnswers = 0
                self?.showLoadingIndicator()
                self?.questionFactory?.loadData()
            }
            
            let errorMessage: String
            switch error {
            case .codeError(let statusCode):
                errorMessage = "Ошибка HTTP с кодом \(statusCode)"
            case .invalidAPIKey(let message):
                errorMessage = "Неверный API ключ: \(message)"
            case .loadImageError(let message):
                errorMessage = "Ошибка загрузки изображения: \(message)"
            case .unexpectedResponse:
                errorMessage = "Неожиданный ответ сервера"
            }
            
            let alertModel = AlertModel(
                title: "Ошибка",
                message: errorMessage,
                buttonText: "Попробовать еще раз",
                completion: errorCompletion
            )
            self?.alertPresenter?.presentAlert(with: alertModel)
        }
    }
    
    func willLoadNextQuestion() {
        showLoadingIndicator()
    }
    
    func didFailLoadingImage(with error: NetworkClient.NetworkErrors) {
        hideLoadingIndicator()
        showAlert(with: error)
    }
    
    private func showAlert(with error: NetworkClient.NetworkErrors) {
        let alertModel = AlertModel(
            title: "Ошибка загрузки",
            message: error.localizedDescription,
            buttonText: "OK",
            completion: { [weak self] in
                self?.questionFactory?.loadData() // Попытка перезагрузить данные
            }
        )
        alertPresenter?.presentAlert(with: alertModel)
    }
    
    
    // MARK: - Properties
    private var currentQuestionIndex = 0  // индекс текущего вопроса
    private var correctAnswers = 0        // счетчик правильных ответов
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private let statisticService: StatisticServiceProtocol = StatisticService()
    
    // MARK: - Outlets
    @IBOutlet private var questionTitleLabel: UILabel!
    @IBOutlet private var indexLabel: UILabel!
    @IBOutlet private var previewImage: UIImageView!
    @IBOutlet private var questionLabel: UILabel!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        questionLabel.numberOfLines = 0
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        alertPresenter = AlertPresenter(viewController: self)
        
        //showNextQuestion()
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // Переопределение preferredStatusBarStyle для изменения цвета элементов статусбара
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        hideLoadingIndicator() // Скрываем индикатор загрузки
        guard let question = question else {
            showQuizResults()
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
            self?.yesButton.isEnabled = true
            self?.noButton.isEnabled = true
            self?.questionTitleLabel.text = "Вопрос:"
        }
    }
    
    // MARK: - Setup
    private func setupButtons() {
        noButton.layer.cornerRadius = 15
        noButton.clipsToBounds = true
        
        yesButton.layer.cornerRadius = 15
        yesButton.clipsToBounds = true
        
        yesButton.isExclusiveTouch = true
        noButton.isExclusiveTouch = true
    }
    
    // MARK: - Private Methods
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func showNextQuestion() {
        questionFactory?.requestNextQuestion()
    }
    
    private func show(quiz step: QuizStepViewModel) {
        previewImage.image = step.image
        questionLabel.text = step.question
        indexLabel.text = step.questionNumber
        resetImageBorder()
    }
    
    private func resetImageBorder() {
        previewImage.layer.borderColor = UIColor.clear.cgColor // сброс цвета рамки
        previewImage.layer.borderWidth = 0                     // толщина рамки
        previewImage.layer.cornerRadius = 20  // радиус скругления углов рамки
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        correctAnswers += isCorrect ? 1 : 0
        updateImageBorder(isCorrect: isCorrect)
        questionTitleLabel.text = isCorrect ? "Верно!" : "Неверно!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
        }
    }
    
    private func updateImageBorder(isCorrect: Bool) {
        previewImage.layer.masksToBounds = true  // даем разрешение на рисование рамки
        previewImage.layer.borderWidth = 8       // толщина рамки
        previewImage.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    
    private func showQuizResults() {
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        
        let bestGame = statisticService.bestGame
        let averageAccuracy = statisticService.totalAccuracy
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy HH:mm"
        let recordDateString = dateFormatter.string(from: bestGame.date)
        
        let message = """
                Ваш результат: \(correctAnswers)/\(questionsAmount)
                Количество сыгранных квизов: \(statisticService.gamesCount)
                Рекорд: \(bestGame.correct)/\(bestGame.total) (\(recordDateString))
                Средняя точность: \(String(format: "%.2f", averageAccuracy))%
                """
        
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: message,
            buttonText: "Сыграть ещё раз",
            completion: { [weak self] in
                self?.resetQuiz()
            }
        )
        alertPresenter?.presentAlert(with: alertModel)
    }
    
    private func resetQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        yesButton.isEnabled = true
        noButton.isEnabled = true
        showNextQuestion()
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex >= questionsAmount - 1 {
            yesButton.isEnabled = false
            noButton.isEnabled = false
            showQuizResults()
        } else {
            currentQuestionIndex += 1
            showNextQuestion()
        }
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false // говорим, что индикатор загрузки не скрыт
        activityIndicator.startAnimating() // включаем анимацию
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating() // Останавливаем анимацию индикатора
        activityIndicator.isHidden = true // Скрываем индикатор загрузки
    }
    
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
}



/*
 Картинка: The Godfather
 Настоящий рейтинг: 9,2
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Dark Knight
 Настоящий рейтинг: 9
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Kill Bill
 Настоящий рейтинг: 8,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Avengers
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Deadpool
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Green Knight
 Настоящий рейтинг: 6,6
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Old
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: The Ice Age Adventures of Buck Wild
 Настоящий рейтинг: 4,3
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: Tesla
 Настоящий рейтинг: 5,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: Vivarium
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 */
