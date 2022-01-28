import Foundation

extension Action {

    public func getOrCreateAssociatedTokenAccount(
        owner: PublicKey,
        tokenMint: PublicKey,
        onComplete: @escaping (Result<(transactionId: TransactionID?, associatedTokenAddress: PublicKey), Error>) -> Void
    ) {
        guard case let .success(associatedAddress) = PublicKey.associatedTokenAddress(
            walletAddress: owner,
            tokenMintAddress: tokenMint
        ) else {
            onComplete(.failure(SolanaError.other("Could not create associated token account")))
            return
        }

        api.getAccountInfo(
            account: associatedAddress.base58EncodedString,
            decodedTo: AccountInfo.self
        ) { acountInfoResult in
            switch acountInfoResult {
            case .success(let info):
                if info.owner == PublicKey.tokenProgramId.base58EncodedString &&
                    info.data.value != nil {
                    onComplete(.success((transactionId: nil, associatedTokenAddress: associatedAddress)))
                    return
                }
                self.createAssociatedTokenAccount(
                    for: owner,
                    tokenMint: tokenMint
                ) { createAssociatedResult in
                    switch createAssociatedResult {
                    case .success(let transactionId):
                        onComplete(.success((transactionId: transactionId, associatedTokenAddress: associatedAddress)))
                        return
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

    public func createAssociatedTokenAccount(
        for owner: PublicKey,
        tokenMint: PublicKey,
        payer: Account? = nil,
        onComplete: @escaping ((Result<TransactionID, Error>) -> Void)
    ) {
        // get account
        guard let payer = try? payer ?? auth.account.get() else {
            return onComplete(.failure(SolanaError.unauthorized))
        }

        guard case let .success(associatedAddress) = PublicKey.associatedTokenAddress(
                walletAddress: owner,
                tokenMintAddress: tokenMint
            ) else {
                onComplete(.failure(SolanaError.other("Could not create associated token account")))
                return
            }

            // create instruction
            let instruction = AssociatedTokenProgram
                .createAssociatedTokenAccountInstruction(
                    mint: tokenMint,
                    associatedAccount: associatedAddress,
                    owner: owner,
                    payer: payer.publicKey
                )

            // send transaction
            serializeAndSendWithFee(
                instructions: [instruction],
                signers: [payer]
            ) { serializeResult in
                switch serializeResult {
                case .success(let reesult):
                    onComplete(.success(reesult))
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
    func getOrCreateAssociatedTokenAccount(
        owner: PublicKey,
        tokenMint: PublicKey
    ) async throws -> (transactionId: TransactionID?, associatedTokenAddress: PublicKey) {
        try await withCheckedThrowingContinuation { c in
            self.getOrCreateAssociatedTokenAccount(owner: owner, tokenMint: tokenMint, onComplete: c.resume(with:))
        }
    }
    
    func createAssociatedTokenAccount(
        for owner: PublicKey,
        tokenMint: PublicKey,
        payer: Account? = nil
    ) async throws -> TransactionID {
        try await withCheckedThrowingContinuation { c in
            self.createAssociatedTokenAccount(for: owner, tokenMint: tokenMint, payer: payer, onComplete: c.resume(with:))
        }
    }
}

extension ActionTemplates {

    public struct CreateAssociatedTokenAccountAction: ActionTemplate {
        public init(owner: PublicKey, tokenMint: PublicKey, payer: Account?) {
            self.owner = owner
            self.tokenMint = tokenMint
            self.payer = payer
        }

        public typealias Success = TransactionID
        public let owner: PublicKey
        public let tokenMint: PublicKey
        public let payer: Account?

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<TransactionID, Error>) -> Void) {
            actionClass.createAssociatedTokenAccount(
                for: owner,
                   tokenMint: tokenMint,
                   payer: payer,
                   onComplete: completion
            )
        }
    }

    public struct GetOrCreateAssociatedTokenAccountAction: ActionTemplate {
        public init(owner: PublicKey, tokenMint: PublicKey) {
            self.owner = owner
            self.tokenMint = tokenMint
        }

        public typealias Success = (transactionId: TransactionID?, associatedTokenAddress: PublicKey)
        public let owner: PublicKey
        public let tokenMint: PublicKey

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Success, Error>) -> Void) {
            actionClass.getOrCreateAssociatedTokenAccount(owner: owner, tokenMint: tokenMint, onComplete: completion)
        }
    }
}
