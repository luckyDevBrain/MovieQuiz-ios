import UIKit

// MARK: - ViewModel для "Вопроса квиза"
struct QuizQuestion {
    let image: String        // изображение фильма
    let text: String         // вопрос о рейтинге фильма
    let correctAnswer: Bool  // правильный ответ на вопрос
}

// MARK: - ViewModel для состояния "Вопрос показан"
struct QuizStepViewModel {
    let image: UIImage          // картинка с афишей фильма
    let question: String        // вопрос о рейтинге квиза
    let questionNumber: String  // порядковый номер вопроса (ex. "1/10")
}

// MARK: - ViewModel для состояния "Результат квиза"
struct QuizResultsViewModel {
    let title: String             // заголовок алерта
    let text: String              // текст о количестве набранных очков
    let buttonText: String        // текст для кнопки алерта
}

final class MovieQuizViewController: UIViewController {
    // MARK: - Properties
    // массив как переменная с mock-данными
    private static let questions: [QuizQuestion] = [
        QuizQuestion(
            image: "The Godfather",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Dark Knight",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Kill Bill",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Avengers",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Deadpool",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "The Green Knight",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: true),
        QuizQuestion(
            image: "Old",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "The Ice Age Adventures of Buck Wild",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Tesla",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: false),
        QuizQuestion(
            image: "Vivarium",
            text: "Рейтинг этого фильма\nбольше чем 6?",
            correctAnswer: false)
    ]
    private var currentQuestionIndex = 0  // индекс текущего вопроса
    private var correctAnswers = 0        // счетчик правильных ответов
    private var totalQuizzesPlayed = 0
    private var totalCorrectAnswers = 0
    private var highScore = 0
    private var highScoreDate = Date()
    
    // MARK: - Outlets
    @IBOutlet private var questionTitleLabel: UILabel!
    @IBOutlet private var indexLabel: UILabel!
    @IBOutlet private var previewImage: UIImageView!
    @IBOutlet private var questionLabel: UILabel!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        showNextQuestion()
        
        questionLabel.numberOfLines = 0
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
        guard !MovieQuizViewController.questions.isEmpty else {
            fatalError("Массив вопросов пуст")
        }
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(MovieQuizViewController.questions.count)")
        return questionStep
    }
    
    private func showNextQuestion() {
        let question = MovieQuizViewController.questions[currentQuestionIndex]
        let viewModel = convert(model: question)
        show(quiz: viewModel)
        yesButton.isEnabled = true
        noButton.isEnabled = true
        questionTitleLabel.text = "Вопрос:"
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
    
    private func show(quiz result: QuizResultsViewModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { _ in
            self.resetQuiz()
        }
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func resetQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        yesButton.isEnabled = true
        noButton.isEnabled = true
        showNextQuestion()
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == MovieQuizViewController.questions.count - 1 {
            yesButton.isEnabled = false
            noButton.isEnabled = false
            showQuizResults()
        } else {
            currentQuestionIndex += 1
            showNextQuestion()
        }
    }
    
    private func showQuizResults() {
        updateStatistics(withNewScore: correctAnswers)
        
        let averageAccuracy = Double(totalCorrectAnswers) / Double(totalQuizzesPlayed * MovieQuizViewController.questions.count) * 100
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yy HH:mm"
        let recordDateString = dateFormatter.string(from: highScoreDate)
        
        let resultText = """
                Ваш результат: \(correctAnswers)/\(MovieQuizViewController.questions.count)
                Количество сыгранных квизов: \(totalQuizzesPlayed)
                Рекорд: \(highScore)/\(MovieQuizViewController.questions.count) (\(recordDateString))
                Средняя точность: \(String(format: "%.2f", averageAccuracy))%
                """
        
        let viewModel = QuizResultsViewModel(
            title: "Этот раунд окончен!",
            text: resultText,
            buttonText: "Сыграть ещё раз"
        )
        show(quiz: viewModel)
    }
    
    private func updateStatistics(withNewScore score: Int) {
        totalQuizzesPlayed += 1
        totalCorrectAnswers += score
        if score > highScore {
            highScore = score
            highScoreDate = Date()
        }
    }
    
    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        let currentQuestion = MovieQuizViewController.questions[currentQuestionIndex]
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        yesButton.isEnabled = false
        noButton.isEnabled = false
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        let currentQuestion = MovieQuizViewController.questions[currentQuestionIndex]
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
