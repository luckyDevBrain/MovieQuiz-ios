//
//  NetworkClient.swift
//  MovieQuiz
//
//  Created by Kirill on 11.06.2024.
//

import Foundation

enum NetworkError: Error {
    case codeError(Int)
    case invalidAPIKey(String)
    case loadImageError(String)
    case unexpectedResponse
    case customError(String)
}

protocol NetworkRouting {
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void)
}

struct NetworkClient: NetworkRouting {
    
    func fetch(url: URL, handler: @escaping (Result<Data, Error>) -> Void) {
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    // Проверяем, пришла ли ошибка
                    if let error = error {
                        handler(.failure(error))
                        return
                    }
                    
                    // Проверяем, что пришёл успешный код ответа
                    if let response = response as? HTTPURLResponse {
                        if response.statusCode < 200 || response.statusCode >= 300 {
                            handler(.failure(NetworkError.codeError(response.statusCode)))
                            return
                        }
                    } else {
                        handler(.failure(NetworkError.unexpectedResponse))
                        return
                    }
                    
                    // Возвращаем данные
                    guard let data = data else {
                        handler(.failure(NetworkError.unexpectedResponse))
                        return
                    }
                    handler(.success(data))
                }
                
                task.resume()
            }
        }
