import Foundation

public extension Api {
    func requestAirdrop(account: String, lamports: UInt64, commitment: Commitment? = nil, onComplete: @escaping(Result<String, Error>) -> Void) {
        router.request(parameters: [account, lamports, RequestConfiguration(commitment: commitment)]) { (result: Result<String, Error>) in
            switch result {
            case .success(let hash):
                onComplete(.success(hash))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func requestAirdrop(account: String, lamports: UInt64, commitment: Commitment? = nil) async throws -> String {
        try await withCheckedThrowingContinuation { c in
            self.requestAirdrop(account: account, lamports: lamports, commitment: commitment, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct RequestAirdrop: ApiTemplate {
        public init(account: String, lamports: UInt64, commitment: Commitment? = nil) {
            self.account = account
            self.lamports = lamports
            self.commitment = commitment
        }
        
        public let account: String
        public let lamports: UInt64
        public let commitment: Commitment?
        
        public typealias Success = String
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.requestAirdrop(account: account, lamports: lamports, commitment: commitment, onComplete: completion)
        }
    }
}
