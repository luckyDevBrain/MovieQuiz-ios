//
//  NetworkClient.swift
//  MovieQuiz
//
//  Created by Kirill on 11.06.2024.
//

import Foundation

/// Отвечает за загрузку данных по URL
struct NetworkClient {
    
    enum NetworkErrors: LocalizedError {
            case invalidAPIKey(String)
            case codeError(Int)
            case loadImageError(String)
            case unexpectedResponse
            
            var errorDescription: String? {
                switch self {
                case .loadImageError(let error):
                    return "Ошибка загрузки изображения: \(error)"
                case .invalidAPIKey(let error):
                    return "Неверный API ключ: \(error)"
                case .codeError(let statusCode):
                    return "Ошибка HTTP с кодом \(statusCode)"
                case .unexpectedResponse:
                    return "Неожиданный ответ сервера"
                }
            }
        }
        
        
        func fetch(url: URL, handler: @escaping (Result<Data, NetworkErrors>) -> Void) {
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    // Проверяем, пришла ли ошибка
                    if let error = error {
                        handler(.failure(.loadImageError(error.localizedDescription)))
                        return
                    }
                    
                    // Проверяем, что нам пришёл успешный код ответа
                    if let response = response as? HTTPURLResponse {
                        guard (200...299).contains(response.statusCode) else {
                            handler(.failure(.codeError(response.statusCode)))
                            return
                        }
                    } else {
                        handler(.failure(.unexpectedResponse))
                        return
                    }
                    
                    // Возвращаем данные
                    guard let data = data else {
                        handler(.failure(.unexpectedResponse))
                        return
                    }
                    handler(.success(data))
                }
            }
            
            task.resume()
        }
    }
