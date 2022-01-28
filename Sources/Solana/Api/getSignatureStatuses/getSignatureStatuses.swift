import Foundation

public extension Api {
    func getSignatureStatuses(pubkeys: [String], configs: RequestConfiguration? = nil, onComplete: @escaping (Result<[SignatureStatus?], Error>) -> Void) {
        router.request(parameters: [pubkeys, configs]) { (result: Result<Rpc<[SignatureStatus?]?>, Error>) in
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
    func getSignatureStatuses(pubkeys: [String], configs: RequestConfiguration? = nil) async throws -> [SignatureStatus?] {
        try await withCheckedThrowingContinuation { c in
            self.getSignatureStatuses(pubkeys: pubkeys, configs: configs, onComplete: c.resume(with:))
        }
    }
}

public extension ApiTemplates {
    struct GetSignatureStatuses: ApiTemplate {
        public init(pubkeys: [String], configs: RequestConfiguration? = nil) {
            self.pubkeys = pubkeys
            self.configs = configs
        }
        
        public let pubkeys: [String]
        public let configs: RequestConfiguration?
        
        public typealias Success = [SignatureStatus?]
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getSignatureStatuses(pubkeys: pubkeys, configs: configs, onComplete: completion)
        }
    }
}
