import Foundation

public extension Api {
    func getInflationRate(onComplete: @escaping(Result<InflationRate, Error>) -> Void) {
        router.request { (result: Result<InflationRate, Error>) in
            switch result {
            case .success(let rate):
                onComplete(.success(rate))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getInflationRate() async throws -> InflationRate {
        try await withCheckedThrowingContinuation { c in
            self.getInflationRate(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetInflationRate: ApiTemplate {
        public init() {}
        
        public typealias Success = InflationRate
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getInflationRate(onComplete: completion)
        }
    }
}
