import Foundation

extension Action {
    public func sendSPLTokens(
        mintAddress: String,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64,
        allowUnfundedRecipient: Bool = false,
        onComplete: @escaping (Result<TransactionID, Error>) -> Void
    ) {
        guard let account = try? self.auth.account.get() else {
            return onComplete(.failure(SolanaError.unauthorized))
        }

        ContResult.init { cb in
            self.findSPLTokenDestinationAddress(
                mintAddress: mintAddress,
                destinationAddress: destinationAddress,
                allowUnfundedRecipient: allowUnfundedRecipient
            ) { cb($0) }
        }.flatMap { (destination, isUnregisteredAsocciatedToken) in

            let toPublicKey = destination

            // catch error
            guard fromPublicKey != toPublicKey.base58EncodedString else {
                return .failure(SolanaError.invalidPublicKey)
            }

            guard let fromPublicKey = PublicKey(string: fromPublicKey) else {
                return .failure( SolanaError.invalidPublicKey)
            }
            var instructions = [TransactionInstruction]()

            // create associated token address
            if isUnregisteredAsocciatedToken {
                guard let mint = PublicKey(string: mintAddress) else {
                    return .failure(SolanaError.invalidPublicKey)
                }
                guard let owner = PublicKey(string: destinationAddress) else {
                    return .failure(SolanaError.invalidPublicKey)
                }

                let createATokenInstruction = AssociatedTokenProgram.createAssociatedTokenAccountInstruction(
                    mint: mint,
                    associatedAccount: toPublicKey,
                    owner: owner,
                    payer: account.publicKey
                )
                instructions.append(createATokenInstruction)
            }

            // send instruction
            let sendInstruction = TokenProgram.transferInstruction(
                tokenProgramId: .tokenProgramId,
                source: fromPublicKey,
                destination: toPublicKey,
                owner: account.publicKey,
                amount: amount
            )

            instructions.append(sendInstruction)
            return .success((instructions: instructions, account: account))

        }.flatMap { (instructions, account) in
            ContResult.init { cb in
                self.serializeAndSendWithFee(instructions: instructions, signers: [account]) {
                    cb($0)
                }
            }
        }.run(onComplete)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func sendSPLTokens(
        mintAddress: String,
        decimals: Decimals,
        from fromPublicKey: String,
        to destinationAddress: String,
        amount: UInt64
    ) async throws -> TransactionID {
        try await withCheckedThrowingContinuation { c in
            self.sendSPLTokens(
                mintAddress: mintAddress,
                from: fromPublicKey,
                to: destinationAddress,
                amount: amount,
                onComplete: c.resume(with:)
            )
        }
    }
}

extension ActionTemplates {
    public struct SendSPLTokens: ActionTemplate {
        public let mintAddress: String
        public let fromPublicKey: String
        public let destinationAddress: String
        public let amount: UInt64
        public let allowUnfundedRecipient: Bool

        public typealias Success = TransactionID

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<TransactionID, Error>) -> Void) {
            actionClass.sendSPLTokens(mintAddress: mintAddress, from: fromPublicKey, to: destinationAddress, amount: amount, allowUnfundedRecipient: allowUnfundedRecipient, onComplete: completion)
        }
    }
}
