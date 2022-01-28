import Foundation

public extension Api {
    func minimumLedgerSlot(onComplete: @escaping (Result<UInt64, Error>) -> Void) {
        router.request { (result: Result<UInt64, Error>) in
            switch result {
            case .success(let slot):
                onComplete(.success(slot))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func minimumLedgerSlot() async throws -> UInt64 {
        try await withCheckedThrowingContinuation { c in
            self.minimumLedgerSlot(onComplete: c.resume(with:))
        }
    }
}


public extension ApiTemplates {
    struct MinimumLedgerSlot: ApiTemplate {
        public init() {}
        
        public typealias Success = UInt64
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.minimumLedgerSlot(onComplete: completion)
        }
    }
}
