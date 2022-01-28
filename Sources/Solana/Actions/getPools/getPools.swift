import Foundation

private var mintDatasCache = [Mint]()
private let swapProgramId = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8"
extension Action {
    struct ParsedSwapInfo: Codable {
        let address: String
        let info: TokenSwapInfo
        var mintDatas: ParsedSwapInfoMintDatas?
    }

    struct ParsedSwapInfoMintDatas: Codable {
        var mintA: Mint?
        var mintB: Mint?
        var tokenPool: Mint?
    }

    private func getPool(parsedSwapInfo: ParsedSwapInfo) -> Pool? {
        guard let address = PublicKey(string: parsedSwapInfo.address),
              let tokenAInfo = parsedSwapInfo.mintDatas?.mintA,
              let tokenBInfo = parsedSwapInfo.mintDatas?.mintB,
              let poolTokenMintInfo = parsedSwapInfo.mintDatas?.tokenPool
        else { return nil }
        return Pool(
            address: address,
            tokenAInfo: tokenAInfo,
            tokenBInfo: tokenBInfo,
            poolTokenMint: poolTokenMintInfo,
            swapData: parsedSwapInfo.info
        )
    }

    public func getPools(swapProgramId: String, onComplete: @escaping (Result<[Pool], Error>) -> Void) {
        self.api.getProgramAccounts(publicKey: swapProgramId, decodedTo: TokenSwapInfo.self) { programsResult in
            switch programsResult {
            case .success(let programs):
                // get parsed swap info
                let parseSwapInfo = programs.compactMap { program -> ParsedSwapInfo? in
                    guard let swapData = program.account.data.value else {
                        return nil
                    }
                    guard swapData.mintA.base58EncodedString != "11111111111111111111111111111111",
                          swapData.mintB.base58EncodedString != "11111111111111111111111111111111",
                          swapData.tokenPool.base58EncodedString != "11111111111111111111111111111111"
                    else { return nil }
                    return ParsedSwapInfo(address: program.pubkey, info: swapData)
                }

                // get all mint addresses
                let mintAddresses = parseSwapInfo.reduce([PublicKey](), {
                    var result = $0
                    if !result.contains($1.info.mintA) {
                        result.append($1.info.mintA)
                    }
                    if !result.contains($1.info.mintB) {
                        result.append($1.info.mintB)
                    }
                    if !result.contains($1.info.tokenPool) {
                        result.append($1.info.tokenPool)
                    }
                    return result
                })

                // split array to form multiple requests (max address per request is 100)
                let requestChunks = mintAddresses.chunked(into: 100)
                let dispatchGroup = DispatchGroup()
                var results: [Result<[PublicKey: Mint], Error>] = []
                for chunk in requestChunks {
                    dispatchGroup.enter()
                    self.getMultipleMintDatas(mintAddresses: chunk) { mintDataResult in
                        results.append(mintDataResult)
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    guard results.count > 0 else {
                        onComplete(.failure(SolanaError.nullValue))
                        return
                    }
                    if let dispatchGroupError: Error = results.compactMap({
                        switch $0 {
                        case .success:
                            return nil
                        case .failure(let error):
                            return error
                        }
                    }).compactMap({ $0 }).first {
                        onComplete(.failure(dispatchGroupError))
                        return
                    }

                    let dispatchGroupResults: [[PublicKey: Mint]] = results.compactMap({
                        switch $0 {
                        case .success(let keyMint):
                            return keyMint
                        case .failure:
                            return nil
                        }
                    }).compactMap({ $0 })

                    var mintDatas = [PublicKey: Mint]()
                    for mintData in dispatchGroupResults {
                        for (key, value) in mintData {
                            mintDatas[key] = value
                        }
                    }

                    var parsedInfo = parseSwapInfo
                    for i in 0..<parsedInfo.count {
                        let swapInfo = parsedInfo[i].info
                        parsedInfo[i].mintDatas = .init(
                            mintA: mintDatas[swapInfo.mintA],
                            mintB: mintDatas[swapInfo.mintB],
                            tokenPool: mintDatas[swapInfo.tokenPool]
                        )
                    }
                    let parsedSwapInfosResult = parsedInfo.map { self.getPool(parsedSwapInfo: $0) }.compactMap { $0 }
                    onComplete(.success(parsedSwapInfosResult))
                    return
                }

            case .failure(let error):
                onComplete(.failure(error))
                return
            }

        }
    }

    public func getSwapPools(onComplete: @escaping (Result<[Pool], Error>) -> Void) {
        getPools(swapProgramId: swapProgramId) { result in
            switch result {
            case .success(let pools):
                let pool = pools.filter {
                    $0.tokenABalance?.amountInUInt64 != 0 &&
                        $0.tokenBBalance?.amountInUInt64 != 0
                }
                onComplete(.success(pool))
                return
            case .failure(let error):
                onComplete(.failure(error))
                return
            }
        }
    }

    public func getPoolWithTokenBalances(pool: Pool, onComplete: @escaping (Result<Pool, Error>) -> Void) {
        self.api.getTokenAccountBalance(pubkey: pool.swapData.tokenAccountA.base58EncodedString) { tokenAResult in
            switch tokenAResult {
            case .success(let tokenABalance):
                self.api.getTokenAccountBalance(pubkey: pool.swapData.tokenAccountB.base58EncodedString) { _ in
                   switch tokenAResult {
                   case .success(let tokenBBalance):
                    var pool = pool
                    pool.tokenABalance = tokenABalance
                    pool.tokenBBalance = tokenBBalance
                    onComplete(.success(pool))
                   case .failure(let error):
                       onComplete(.failure(error))
                       return
                   }
                }
            case .failure(let error):
                onComplete(.failure(error))
                return
            }
         }
     }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func getPools(swapProgramId: String) async throws -> [Pool] {
        try await withCheckedThrowingContinuation { c in
            self.getPools(swapProgramId: swapProgramId, onComplete: c.resume(with:))
        }
    }
    func getSwapPools() async throws -> [Pool] {
        try await withCheckedThrowingContinuation { c in
            self.getSwapPools(onComplete: c.resume(with:))
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension ActionTemplates {
    public struct GetPools: ActionTemplate {
        public init(swapProgramId: String) {
            self.swapProgramId = swapProgramId
        }

        public typealias Success =  [Pool]

        public let swapProgramId: String

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<[Pool], Error>) -> Void) {
            actionClass.getPools(swapProgramId: swapProgramId, onComplete: completion)
        }
    }

    public struct GetSwapPools: ActionTemplate {
        public init() { }

        public typealias Success = [Pool]

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<[Pool], Error>) -> Void) {
            actionClass.getSwapPools(onComplete: completion)
        }
    }
}
