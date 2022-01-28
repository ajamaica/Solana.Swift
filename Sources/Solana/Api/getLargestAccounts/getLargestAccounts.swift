import Foundation

public extension Api {
    func getLargestAccounts(onComplete: @escaping(Result<[LargestAccount], Error>) -> Void) {
        router.request { (result: Result<Rpc<[LargestAccount]?>, Error>) in
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
    func getLargestAccounts() async throws -> [LargestAccount] {
        try await withCheckedThrowingContinuation { c in
            self.getLargestAccounts(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetLargestAccounts: ApiTemplate {
        public init() {}
        
        public typealias Success = [LargestAccount]
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getLargestAccounts(onComplete: completion)
        }
    }
}
