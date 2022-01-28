import Foundation

public extension Api {
    func simulateTransaction(transaction: String, configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!, onComplete: @escaping(Result<TransactionStatus, Error>) -> Void) {
        router.request(parameters: [transaction, configs]) { (result: Result<Rpc<TransactionStatus?>, Error>) in
            switch result {
            case .success(let rpc):
                guard let value = rpc.value else {
                    onComplete(.failure(SolanaError.nullValue))
                    return
                }
                onComplete(.success(value))
                return
            case .failure(let error):
                onComplete(.failure(error))
                return
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func simulateTransaction(transaction: String, configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!) async throws -> TransactionStatus {
        try await withCheckedThrowingContinuation { c in
            self.simulateTransaction(transaction: transaction, configs: configs, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct SimulateTransaction: ApiTemplate {
        public init(transaction: String,
                    configs: RequestConfiguration = RequestConfiguration(encoding: "base64")!) {
            self.transaction = transaction
            self.configs = configs
        }
        
        public let transaction: String
        public let configs: RequestConfiguration
        
        public typealias Success = TransactionStatus
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.simulateTransaction(transaction: transaction, configs: configs, onComplete: completion)
        }
    }
}
