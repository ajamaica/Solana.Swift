import Foundation

public extension Api {
    func getGenesisHash(onComplete: @escaping(Result<String, Error>) -> Void) {
        router.request { (result: Result<String, Error>) in
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
    func getGenesisHash() async throws -> String {
        try await withCheckedThrowingContinuation { c in
            self.getGenesisHash(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetGenesisHash: ApiTemplate {
        public init() {}
        
        public typealias Success = String
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getGenesisHash(onComplete: completion)
        }
    }
}
