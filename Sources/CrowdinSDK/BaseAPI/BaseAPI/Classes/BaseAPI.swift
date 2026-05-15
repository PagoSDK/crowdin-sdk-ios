//
//  BaseAPI.swift
//  BaseAPI
//
//  Created by Serhii Londar on 12/8/17.
//

import Foundation

typealias BaseAPICompletion = (Data?, URLResponse?, Error?) -> Swift.Void
typealias BaseAPIResult = SynchronousDataTaskResult

open class BaseAPI {
    var session: URLSession
    private let parsingQueue = DispatchQueue(label: "BaseAPI-parsing-queue")
    
    init() {
        self.session = URLSession(configuration: URLSessionConfiguration.default)
    }
    
    init(session: URLSession) {
        self.session = session
    }
    
    func send(request: URLRequest, completion: @escaping BaseAPICompletion) {
        session.dataTask(with: request, completionHandler: completion).resume()
    }
    
    func send(request: URLRequest) -> BaseAPIResult {
        return session.synchronousDataTask(request: request)
    }
    
    /// MARK - GET
    
    func get(url: String, parameters: [String: String]? = nil, headers: [String: String]? = nil, body: Data? = nil, callbackQueue: DispatchQueue = .main, completion: @escaping BaseAPICompletion) {
        let request = Request(url: url, method: .GET, parameters: parameters, headers: headers, body: body)
        let buildRequest = request.request()
        if let urlRequest = buildRequest.request {
            let task = session.dataTask(with: urlRequest) { (data, response, error) in
                callbackQueue.async { completion(data, response, error) }
            }
            task.resume()
        } else {
            callbackQueue.async { completion(nil, nil, buildRequest.error) }
        }
    }
    
    func get(url: String, parameters: [String: String]? = nil, headers: [String: String]? = nil, body: Data? = nil) -> BaseAPIResult {
        let request = Request(url: url, method: .GET, parameters: parameters, headers: headers, body: body)
        let buildRequest = request.request()
        if let urlRequest = buildRequest.request {
            return session.synchronousDataTask(request: urlRequest)
        } else {
            return (nil, nil, buildRequest.error)
        }
    }
     
}
