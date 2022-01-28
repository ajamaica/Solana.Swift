import Foundation

public extension Api {
    func getVersion(onComplete: @escaping(Result<Version, Error>) -> Void) {
        router.request { (result: Result<Version, Error>) in
            switch result {
            case .success(let version):
                onComplete(.success(version))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getVersion() async throws -> Version {
        try await withCheckedThrowingContinuation { c in
            self.getVersion(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetVersion: ApiTemplate {
        public init() {}
        
        public typealias Success = Version
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getVersion(onComplete: completion)
        }
    }
}
