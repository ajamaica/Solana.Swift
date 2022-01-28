import Foundation

public extension Action {

    func getMintData(mintAddress: PublicKey, programId: PublicKey = .tokenProgramId, onComplete: @escaping ((Result<Mint, Error>) -> Void)) {
        self.api.getAccountInfo(account: mintAddress.base58EncodedString, decodedTo: Mint.self) { result in
            switch result {
            case .success(let account):
                if account.owner != programId.base58EncodedString {
                    onComplete(.failure(SolanaError.other("Invalid mint owner")))
                    return
                }
                if let data = account.data.value {
                    onComplete(.success(data))
                    return
                }
                onComplete(.failure(SolanaError.other("Invalid data")))
                return
            case .failure(let error):
                onComplete(.failure(error))
                return
            }
        }
    }

    func getMultipleMintDatas(mintAddresses: [PublicKey], programId: PublicKey = .tokenProgramId, onComplete: @escaping (Result<[PublicKey: Mint], Error>) -> Void) {

        return ContResult.init { cb in
            self.api.getMultipleAccounts(pubkeys: mintAddresses.map { $0.base58EncodedString }, decodedTo: Mint.self) {
                cb($0)
            }
        }.flatMap {
            let account = $0
            if account.contains(where: {$0.owner != programId.base58EncodedString}) == true {
                return .failure(SolanaError.other("Invalid mint owner"))
            }

            let values = account.compactMap { $0.data.value }
            guard values.count == mintAddresses.count else {
                return .failure(SolanaError.other("Some of mint data are missing"))
            }

            var mintDict = [PublicKey: Mint]()
            for (index, address) in mintAddresses.enumerated() {
                mintDict[address] = values[index]
            }
            return .success(mintDict)
        }.run(onComplete)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func getMintData(mintAddress: PublicKey, programId: PublicKey = .tokenProgramId) async throws -> Mint {
        try await withCheckedThrowingContinuation { c in
            self.getMintData(mintAddress: mintAddress, programId: programId, onComplete: c.resume(with:))
        }
    }
    func getMultipleMintDatas(mintAddresses: [PublicKey], programId: PublicKey = .tokenProgramId) async throws -> [PublicKey: Mint] {
        try await withCheckedThrowingContinuation { c in
            self.getMultipleMintDatas(mintAddresses: mintAddresses, programId: programId, onComplete: c.resume(with:))
        }
    }
}

extension ActionTemplates {
    public struct GetMintData: ActionTemplate {
        public init(programId: PublicKey = .tokenProgramId, mintAddress: PublicKey) {
            self.programId = programId
            self.mintAddress = mintAddress
        }

        public typealias Success = Mint
        public let programId: PublicKey
        public let mintAddress: PublicKey

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Mint, Error>) -> Void) {
            actionClass.getMintData(mintAddress: mintAddress, programId: programId, onComplete: completion)
        }
    }

    public struct GetMultipleMintData: ActionTemplate {
        public init(programId: PublicKey = .tokenProgramId, mintAddresses: [PublicKey]) {
            self.programId = programId
            self.mintAddresses = mintAddresses
        }

        public typealias Success = [PublicKey: Mint]
        public let programId: PublicKey
        public let mintAddresses: [PublicKey]

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<[PublicKey : Mint], Error>) -> Void) {
            actionClass.getMultipleMintDatas(mintAddresses: mintAddresses, programId: programId, onComplete: completion)
        }
    }
}
