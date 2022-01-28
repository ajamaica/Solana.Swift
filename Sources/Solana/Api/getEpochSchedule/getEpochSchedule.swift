import Foundation

public extension Api {
    func getEpochSchedule(onComplete: @escaping (Result<EpochSchedule, Error>) -> Void) {
        router.request { (result: Result<EpochSchedule, Error>) in
            switch result {
            case .success(let epochSheadule):
                onComplete(.success(epochSheadule))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getEpochSchedule() async throws -> EpochSchedule {
        try await withCheckedThrowingContinuation { c in
            self.getEpochSchedule(onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetEpochSchedule: ApiTemplate {
        public init() {}
        
        public typealias Success = EpochSchedule
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getEpochSchedule(onComplete: completion)
        }
    }
}
