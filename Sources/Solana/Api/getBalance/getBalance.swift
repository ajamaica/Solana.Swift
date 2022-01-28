import Foundation

public extension Api {
    func getBalance(account: String? = nil, commitment: Commitment? = nil, onComplete: @escaping(Result<UInt64, Error>) -> Void) {

        guard let account = try? account ?? auth.account.get().publicKey.base58EncodedString
        else {
            onComplete(.failure(SolanaError.unauthorized))
            return
        }
        router.request(parameters: [account, RequestConfiguration(commitment: commitment)]) { (result: Result<Rpc<UInt64?>, Error>) in
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
    func getBalance(account: String? = nil, commitment: Commitment? = nil) async throws -> UInt64 {
        try await withCheckedThrowingContinuation { c in
            self.getBalance(account: account, commitment: commitment, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetBalance: ApiTemplate {
        public init(account: String? = nil, commitment: Commitment? = nil) {
            self.account = account
            self.commitment = commitment
        }
        
        public let account: String?
        public let commitment: Commitment?
        
        public typealias Success = UInt64
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getBalance(account: account, commitment: commitment, onComplete: completion)
        }
    }
}
