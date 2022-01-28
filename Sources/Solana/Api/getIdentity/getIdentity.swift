import Foundation

public extension Api {
    func getIdentity(onComplete: @escaping(Result<Identity, Error>) -> Void) {
        router.request { (result: Result<Identity, Error>) in
            switch result {
            case .success(let identity):
                onComplete(.success(identity))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getIdentity() async throws -> Identity {
        try await withCheckedThrowingContinuation { c in
            self.getIdentity(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetIdentity: ApiTemplate {
        public init() {}
        
        public typealias Success = Identity
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getIdentity(onComplete: completion)
        }
    }
}
