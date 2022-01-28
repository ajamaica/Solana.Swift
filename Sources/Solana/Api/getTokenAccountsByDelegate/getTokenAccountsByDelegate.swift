import Foundation

public extension Api {
    func getTokenAccountsByDelegate(pubkey: String, mint: String? = nil, programId: String? = nil, configs: RequestConfiguration? = nil, onComplete: @escaping (Result<[TokenAccount<AccountInfo>], Error>) -> Void) {

        var parameterMap = [String: String]()
        if let mint = mint {
            parameterMap["mint"] = mint
        } else if let programId =  programId {
            parameterMap["programId"] = programId
        } else {
            onComplete(Result.failure(SolanaError.other("mint or programId are mandatory parameters")))
            return
        }

        router.request(parameters: [pubkey, parameterMap, configs]) { (result: Result<Rpc<[TokenAccount<AccountInfo>]?>, Error>) in
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
    func getTokenAccountsByDelegate(pubkey: String, mint: String? = nil, programId: String? = nil, configs: RequestConfiguration? = nil) async throws -> [TokenAccount<AccountInfo>] {
        try await withCheckedThrowingContinuation { c in
            self.getTokenAccountsByDelegate(pubkey: pubkey, mint: mint, programId: programId, configs: configs, onComplete: c.resume(with:))
        }
    }
}


public extension ApiTemplates {
    struct GetTokenAccountsByDelegate: ApiTemplate {
        public init(pubkey: String, mint: String? = nil, programId: String? = nil, configs: RequestConfiguration? = nil) {
            self.pubkey = pubkey
            self.mint = mint
            self.programId = programId
            self.configs = configs
        }
        
        public let pubkey: String
        public let mint: String?
        public let programId: String?
        public let configs: RequestConfiguration?
        
        public typealias Success = [TokenAccount<AccountInfo>]
        
        public func perform(withConfigurationFrom apiClass: Api, completion: @escaping (Result<Success, Error>) -> Void) {
            apiClass.getTokenAccountsByDelegate(pubkey: pubkey, mint: mint, programId: programId, configs: configs, onComplete: completion)
        }
    }
}
