import Foundation

public extension Api {
    func getTokenLargestAccounts(pubkey: String, commitment: Commitment? = nil, onComplete: @escaping (Result<[TokenAmount], Error>) -> Void) {
        router.request(parameters: [pubkey, RequestConfiguration(commitment: commitment)]) { (result: Result<Rpc<[TokenAmount]?>, Error>) in
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
    func getTokenLargestAccounts(pubkey: String, commitment: Commitment? = nil) async throws -> [TokenAmount] {
        try await withCheckedThrowingContinuation { c in
            self.getTokenLargestAccounts(pubkey: pubkey, commitment: commitment, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetTokenLargestAccounts: ApiTemplate {
        public init(pubkey: String, commitment: Commitment? = nil) {
            self.pubkey = pubkey
            self.commitment = commitment
        }
        
        public let pubkey: String
        public let commitment: Commitment?
        
        public typealias Success = [TokenAmount]
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getTokenLargestAccounts(pubkey: pubkey, commitment: commitment, onComplete: completion)
        }
    }
}
