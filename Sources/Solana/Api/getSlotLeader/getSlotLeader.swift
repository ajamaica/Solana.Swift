import Foundation

public extension Api {
    func getSlotLeader(commitment: Commitment? = nil, onComplete: @escaping (Result<String, Error>) -> Void) {
        router.request(parameters: [RequestConfiguration(commitment: commitment)]) { (result: Result<String, Error>) in
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
    func getSlotLeader(commitment: Commitment? = nil) async throws -> String {
        try await withCheckedThrowingContinuation { c in
            self.getSlotLeader(commitment: commitment, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetSlotLeader: ApiTemplate {
        public init(commitment: Commitment? = nil) {
            self.commitment = commitment
        }
        
        public let commitment: Commitment?
        
        public typealias Success = String
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getSlotLeader(commitment: commitment, onComplete: completion)
        }
    }
}
