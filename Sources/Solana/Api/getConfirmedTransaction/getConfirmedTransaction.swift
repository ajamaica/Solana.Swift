import Foundation

public extension Api {
    func getConfirmedTransaction(transactionSignature: String, onComplete: @escaping (Result<TransactionInfo, Error>) -> Void) {
        router.request(parameters: [transactionSignature, "jsonParsed"]) { (result: Result<TransactionInfo, Error>) in
            switch result {
            case .success(let transactions):
                onComplete(.success(transactions))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getConfirmedTransaction(transactionSignature: String) async throws -> TransactionInfo {
        try await withCheckedThrowingContinuation { c in
            self.getConfirmedTransaction(transactionSignature: transactionSignature, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetConfirmedTransaction: ApiTemplate {
        public init(transactionSignature: String) {
            self.transactionSignature = transactionSignature
        }
        
        public let transactionSignature: String
        
        public typealias Success = TransactionInfo
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getConfirmedTransaction(transactionSignature: transactionSignature, onComplete: completion)
        }
    }
}
