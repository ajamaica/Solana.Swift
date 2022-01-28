import Foundation

public extension Api {
    func getFees(commitment: Commitment? = nil, onComplete: @escaping (Result<Fee, Error>) -> Void) {
        router.request(parameters: [RequestConfiguration(commitment: commitment)]) { (result: Result<Rpc<Fee?>, Error>) in
            switch result {
            case .success(let rpc):
                guard let value = rpc.value else {
                    onComplete(.failure(SolanaError.nullValue))
                    return
                }
                onComplete(.success(value))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getFees(commitment: Commitment? = nil) async throws -> Fee {
        try await withCheckedThrowingContinuation { c in
            self.getFees(commitment: commitment, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetFees: ApiTemplate {
        public init(commitment: Commitment? = nil) {
            self.commitment = commitment
        }
        
        public let commitment: Commitment?
        
        public typealias Success = Fee
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getFees(commitment: commitment, onComplete: completion)
        }
    }
}
