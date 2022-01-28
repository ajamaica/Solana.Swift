import Foundation

public extension Api {
    func getFeeRateGovernor(onComplete: @escaping (Result<Fee, Error>) -> Void) {
        router.request { (result: Result<Rpc<Fee?>, Error>) in
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
    func getFeeRateGovernor() async throws -> Fee {
        try await withCheckedThrowingContinuation { c in
            self.getFeeRateGovernor(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetFeeRateGovernor: ApiTemplate {
        public init() {}
        
        public typealias Success = Fee
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getFeeRateGovernor(onComplete: completion)
        }
    }
}
