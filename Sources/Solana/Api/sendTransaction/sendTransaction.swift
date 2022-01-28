import Foundation

public extension Api {
    func sendTransaction(serializedTransaction: String,
                         configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!,
                         onComplete: @escaping(Result<TransactionID, Error>) -> Void) {
        router.request(parameters: [serializedTransaction, configs]) { (result: Result<TransactionID, Error>) in
            switch result {
            case .success(let transaction):
                onComplete(.success(transaction))
            case .failure(let error):
                if let solanaError = error as? SolanaError {
                    onComplete(.failure(self.handleError(error: solanaError)))
                    return
                } else {
                    onComplete(.failure(error))
                    return
                }
            }
        }
    }

    fileprivate func handleError(error: SolanaError) -> Error {
        if case .invalidResponse(let response) = error,
           response.message != nil {
            var message = response.message
            if let readableMessage = response.data?.logs
                .first(where: { $0.contains("Error:") })?
                .components(separatedBy: "Error: ")
                .last {
                message = readableMessage
            } else if let readableMessage = response.message?
                        .components(separatedBy: "Transaction simulation failed: ")
                        .last {
                message = readableMessage
            }
            return SolanaError.invalidResponse(ResponseError(code: response.code, message: message, data: response.data))
        }
        return error
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func sendTransaction(serializedTransaction: String,
                         configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!) async throws -> TransactionID {
        try await withCheckedThrowingContinuation { c in
            self.sendTransaction(serializedTransaction: serializedTransaction, configs: configs, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct SendTransaction: ApiTemplate {
        public init(serializedTransaction: String,
                    configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!) {
            self.serializedTransaction = serializedTransaction
            self.configs = configs
        }
        
        public let serializedTransaction: String
        public let configs: RequestConfiguration
        
        public typealias Success = TransactionID
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.sendTransaction(serializedTransaction: serializedTransaction, configs: configs, onComplete: completion)
        }
    }
}
