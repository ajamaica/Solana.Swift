import Foundation

public extension Api {
    func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64, onComplete: @escaping (Result<[UInt64], Error>) -> Void) {
        router.request(parameters: [startSlot, limit]) { (result: Result<[UInt64], Error>) in
            switch result {
            case .success(let confirmedBlocks):
                onComplete(.success(confirmedBlocks))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Api {
    func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64) async throws -> [UInt64] {
        try await withCheckedThrowingContinuation { c in
            self.getConfirmedBlocksWithLimit(startSlot: startSlot, limit: limit, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetConfirmedBlocksWithLimit: ApiTemplate {
        public init(startSlot: UInt64, limit: UInt64) {
            self.startSlot = startSlot
            self.limit = limit
        }
        
        public let startSlot: UInt64
        public let limit: UInt64
        
        public typealias Success = [UInt64]
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getConfirmedBlocksWithLimit(startSlot: startSlot, limit: limit, onComplete: completion)
        }
    }
}
