import Foundation

extension Action {
    public func closeTokenAccount(
        account: Account? = nil,
        tokenPubkey: String,
        onComplete: @escaping (Result<TransactionID, Error>) -> Void
    ) {
        guard let account = try? account ?? auth.account.get() else {
            onComplete(.failure(SolanaError.unauthorized))
            return
        }
        guard let tokenPubkey = PublicKey(string: tokenPubkey) else {
            onComplete(.failure(SolanaError.invalidPublicKey))
            return
        }

        let instruction = TokenProgram.closeAccountInstruction(
            account: tokenPubkey,
            destination: account.publicKey,
            owner: account.publicKey
        )
        serializeAndSendWithFee(instructions: [instruction], signers: [account]) {
            onComplete($0)
            return
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func closeTokenAccount(
        account: Account? = nil,
        tokenPubkey: String
    ) async throws -> TransactionID {
        try await withCheckedThrowingContinuation { c in
            self.closeTokenAccount(account: account, tokenPubkey: tokenPubkey, onComplete: c.resume(with:))
        }
    }
}

extension ActionTemplates {
    public struct CloseTokenAccountAction: ActionTemplate {
        public init(account: Account?, tokenPubkey: String) {
            self.account = account
            self.tokenPubkey = tokenPubkey
        }

        public typealias Success = TransactionID

        public let account: Account?
        public let tokenPubkey: String

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Success, Error>) -> Void) {
            actionClass.closeTokenAccount(account: account, tokenPubkey: tokenPubkey, onComplete: completion)
        }
    }
}
