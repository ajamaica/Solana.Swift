import Foundation

extension Action {
    public typealias SPLTokenDestinationAddress = (destination: PublicKey, isUnregisteredAsocciatedToken: Bool)
    
    public func findSPLTokenDestinationAddress(
        mintAddress: String,
        destinationAddress: String,
        allowUnfundedRecipient: Bool = false,
        onComplete: @escaping (Result<SPLTokenDestinationAddress, Error>) -> Void
    ) {
        if allowUnfundedRecipient {
            checkSPLTokenAccountExistence(
                mintAddress: mintAddress,
                destinationAddress: destinationAddress,
                onComplete: onComplete
            )
        } else {
            findSPLTokenDestinationAddressOfExistingAccount(
                mintAddress: mintAddress,
                destinationAddress: destinationAddress,
                onComplete: onComplete
            )
        }
    }
    
    fileprivate func checkSPLTokenAccountExistence(
        mintAddress: String,
        destinationAddress: String,
        onComplete: @escaping (Result<SPLTokenDestinationAddress, Error>) -> Void
    ) {
        guard
            let owner = PublicKey(string: destinationAddress),
            let tokenMint = PublicKey(string: mintAddress),
            case let .success(associatedTokenAddress) = PublicKey.associatedTokenAddress(walletAddress: owner, tokenMintAddress: tokenMint)
        else {
            onComplete(.failure(SolanaError.invalidPublicKey))
            return
        }
        
        self.api.getAccountInfo(account: associatedTokenAddress.base58EncodedString, decodedTo: AccountInfo.self) { result in
            let hasAssociatedTokenAccount: Bool
            
            switch result {
            case .failure(let error):
                guard let solanaError = error as? SolanaError,
                      case .nullValue = solanaError
                else {
                    onComplete(.failure(error))
                    return
                }
                
                hasAssociatedTokenAccount = false
            case .success:
                hasAssociatedTokenAccount = true
            }
            
            onComplete(.success((associatedTokenAddress, !hasAssociatedTokenAccount)))
        }
    }
    
    fileprivate func findSPLTokenDestinationAddressOfExistingAccount(
        mintAddress: String,
        destinationAddress: String,
        onComplete: @escaping (Result<SPLTokenDestinationAddress, Error>) -> Void
    ) {
        ContResult<BufferInfo<AccountInfo>, Error>.init { cb in
            self.api.getAccountInfo(
                account: destinationAddress,
                decodedTo: AccountInfo.self
            ) { cb($0) }
        }.flatMap { info in
            let toTokenMint = info.data.value?.mint.base58EncodedString
            var toPublicKeyString: String = ""
            if mintAddress == toTokenMint {
                // detect if destination address is already a SPLToken address
                toPublicKeyString = destinationAddress
            } else if info.owner == PublicKey.programId.base58EncodedString {
                // detect if destination address is a SOL address
                guard let owner = PublicKey(string: destinationAddress) else {
                    return .failure(SolanaError.invalidPublicKey)
                }
                guard let tokenMint = PublicKey(string: mintAddress) else {
                    return .failure(SolanaError.invalidPublicKey)
                }

                // create associated token address
                guard case let .success(address) = PublicKey.associatedTokenAddress(
                    walletAddress: owner,
                    tokenMintAddress: tokenMint
                ) else {
                    return .failure(SolanaError.invalidPublicKey)
                }

                toPublicKeyString = address.base58EncodedString
            }

            guard let toPublicKey = PublicKey(string: toPublicKeyString) else {
                return .failure(SolanaError.invalidPublicKey)
            }

            if destinationAddress != toPublicKey.base58EncodedString {
                // check if associated address is already registered
                return ContResult.init { cb in
                    self.api.getAccountInfo(
                        account: toPublicKey.base58EncodedString,
                        decodedTo: AccountInfo.self
                    ) { cb($0)}
                }.flatMap { info1 in
                    var isUnregisteredAsocciatedToken = true
                    // if associated token account has been registered
                    if info1.owner == PublicKey.tokenProgramId.base58EncodedString &&
                        info.data.value != nil {
                        isUnregisteredAsocciatedToken = false
                    }
                    return .success((destination: toPublicKey, isUnregisteredAsocciatedToken: isUnregisteredAsocciatedToken))
                }
            } else {
                return .success((destination: toPublicKey, isUnregisteredAsocciatedToken: false))
            }
        }.run(onComplete)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func findSPLTokenDestinationAddress(
        mintAddress: String,
        destinationAddress: String
    ) async throws -> SPLTokenDestinationAddress {
        try await withCheckedThrowingContinuation { c in
            self.findSPLTokenDestinationAddress(mintAddress: mintAddress, destinationAddress: destinationAddress, onComplete: c.resume(with:))
        }
    }
}

extension ActionTemplates {
    public struct FindSPLTokenDestinationAddress: ActionTemplate {
        public init(mintAddress: String, destinationAddress: String, allowUnfundedRecipient: Bool) {
            self.mintAddress = mintAddress
            self.destinationAddress = destinationAddress
            self.allowUnfundedRecipient = allowUnfundedRecipient
        }

        public typealias Success = Action.SPLTokenDestinationAddress
        public let mintAddress: String
        public let destinationAddress: String
        public let allowUnfundedRecipient: Bool

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Action.SPLTokenDestinationAddress, Error>) -> Void) {
            actionClass.findSPLTokenDestinationAddress(mintAddress: mintAddress, destinationAddress: destinationAddress, allowUnfundedRecipient: allowUnfundedRecipient, onComplete: completion)
        }
    }
}
