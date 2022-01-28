import Foundation

private let swapProgramId = "SwaPpA9LAaLfeLi3a68M4DjnLqgtticKg6CnyNwgAC8"
extension Action {
    public struct SwapResponse {
        public let transactionId: String
        public let newWalletPubkey: String?
    }

    public func swap(
        account: Account? = nil,
        pool: Pool? = nil,
        source: PublicKey,
        sourceMint: PublicKey,
        destination: PublicKey? = nil,
        destinationMint: PublicKey,
        slippage: Double,
        amount: UInt64,
        onComplete: @escaping(Result<SwapResponse, Error>) -> Void
    ) {
        // verify account
        guard let owner = try? account ?? auth.account.get() else {
             onComplete(.failure(SolanaError.unauthorized))
            return
        }

        // reduce pools
        var getPoolRequest: ContResult<Pool, Error>
        if let pool = pool {
            getPoolRequest = ContResult<Pool, Error>.init { $0(.success(pool)) }
        } else {
            getPoolRequest = ContResult<Pool, Error>.init { cb in
                self.getSwapPools { poolsResult in
                    switch poolsResult {
                    case .success(let pools):
                        if let matchPool = pools.matchedPool(
                            sourceMint: sourceMint.base58EncodedString,
                            destinationMint: destinationMint.base58EncodedString
                        ) {
                            cb(.success(matchPool))
                            return
                        }
                        cb(.failure(SolanaError.other("Unsupported swapping tokens")))
                        return
                    case .failure(let error):
                        cb(.failure(error))
                        return
                    }

                }
            }
        }

        let accountInfoCall: (Pool) -> ContResult<AccountInfo, Error> = { pool in
            ContResult<AccountInfo, Error>.init { cb in
                self.getAccountInfoData(
                    account: pool.swapData.tokenAccountA.base58EncodedString,
                    tokenProgramId: .tokenProgramId
                ) {
                    cb($0)
                }
            }
        }

        let balanceCall = ContResult<UInt64, Error>.init { cb in
            self.api.getMinimumBalanceForRentExemption(dataLength: UInt64(AccountInfo.BUFFER_LENGTH)) {
                cb($0)
            }
        }

        getPoolRequest.flatMap { pool in
            return ContResult<(accountInfo: AccountInfo, balance: UInt64), Error>.flatMap2(accountInfoCall(pool), balanceCall, f: { account, balance in
                return  .success((account, balance))
            })
        }.flatMap { (accountInfo: AccountInfo, balance: UInt64) -> ContResult<SwapResponse, Error> in
            guard let pool = pool,
                  let poolAuthority = pool.authority,
                  let estimatedAmount = pool.estimatedAmount(forInputAmount: amount, includeFees: true),
                  let _ = UInt64(pool.tokenBBalance?.amount ?? "") else {
                return .failure(SolanaError.other("Swap pool is not valid"))
            }
            // get variables

            let tokenAInfo = accountInfo
            let minimumBalanceForRentExemption = balance

            let minAmountIn = pool.minimumReceiveAmount(estimatedAmount: estimatedAmount, slippage: slippage)

            // find account
            var source = source
            var destination = destination

            // add userTransferAuthority
            guard let userTransferAuthority = Account(network: self.router.endpoint.network) else {
                return .failure(SolanaError.other("Unsupported swapping tokens"))
            }

            // form signers
            var signers = [owner, userTransferAuthority]

            // form instructions
            var instructions = [TransactionInstruction]()
            var cleanupInstructions = [TransactionInstruction]()

            // create fromToken if it is native
            if tokenAInfo.isNative {
                guard let newAccount = try? self.createWrappedSolAccount(
                    fromAccount: source,
                    amount: amount,
                    payer: owner.publicKey,
                    instructions: &instructions,
                    cleanupInstructions: &cleanupInstructions,
                    signers: &signers,
                    minimumBalanceForRentExemption: minimumBalanceForRentExemption
                ).get() else {
                    return .failure(SolanaError.other("Could not create Wrapped SolAccount"))
                }

                source = newAccount.publicKey
            }

            // check toToken
            var newWalletPubkey: String?

            let isMintBWSOL = destinationMint == .wrappedSOLMint
            if destination == nil || isMintBWSOL {
                // create toToken if it doesn't exist
                guard let newAccount = try? self.createAccountByMint(
                    owner: owner.publicKey,
                    mint: destinationMint,
                    instructions: &instructions,
                    cleanupInstructions: &cleanupInstructions,
                    signers: &signers,
                    minimumBalanceForRentExemption: minimumBalanceForRentExemption
                ).get() else {
                    return .failure(SolanaError.other("Could not create Wrapped SolAccount"))
                }

                destination = newAccount.publicKey
                newWalletPubkey = destination?.base58EncodedString
            }

            // approve
            instructions.append(
                TokenProgram.approveInstruction(
                    tokenProgramId: .tokenProgramId,
                    account: source,
                    delegate: userTransferAuthority.publicKey,
                    owner: owner.publicKey,
                    amount: amount
                )
            )

            guard let swapProgramId = PublicKey(string: swapProgramId) else {
                return .failure(SolanaError.invalidPublicKey)
            }
            // swap
            instructions.append(
                TokenSwapProgram.swapInstruction(
                    tokenSwap: pool.address,
                    authority: poolAuthority,
                    userTransferAuthority: userTransferAuthority.publicKey,
                    userSource: source,
                    poolSource: pool.swapData.tokenAccountA,
                    poolDestination: pool.swapData.tokenAccountB,
                    userDestination: destination!,
                    poolMint: pool.swapData.tokenPool,
                    feeAccount: pool.swapData.feeAccount,
                    hostFeeAccount: nil,
                    swapProgramId: swapProgramId,
                    tokenProgramId: .tokenProgramId,
                    amountIn: amount,
                    minimumAmountOut: minAmountIn
                )
            )

            return ContResult<String, Error>.init { cb in
                self.serializeAndSendWithFee(
                    instructions: instructions + cleanupInstructions,
                    signers: signers
                ) {
                    cb($0)
                }
            }.map {
                SwapResponse(transactionId: $0, newWalletPubkey: newWalletPubkey)
            }
        }.run(onComplete)
    }

    public func getAccountInfoData(account: String,
                                    tokenProgramId: PublicKey,
                                    onComplete: @escaping (Result<AccountInfo, Error>) -> Void) {
        self.api.getAccountInfo(account: account, decodedTo: AccountInfo.self) { accountInfoResult in
            switch accountInfoResult {
            case .success(let account):

                if account.owner != tokenProgramId.base58EncodedString {
                    onComplete(.failure(SolanaError.other("Invalid account owner")))
                    return
                }

                if let info = account.data.value {
                    onComplete(.success(info))
                    return
                }

                onComplete(.failure(SolanaError.other("Invalid data")))
                return
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }

    private func createWrappedSolAccount(
        fromAccount: PublicKey,
        amount: UInt64,
        payer: PublicKey,
        instructions: inout [TransactionInstruction],
        cleanupInstructions: inout [TransactionInstruction],
        signers: inout [Account],
        minimumBalanceForRentExemption: UInt64
    ) -> Result<Account, Error> {
        guard let newAccount = Account(network: self.router.endpoint.network) else {
            return .failure(SolanaError.invalidRequest(reason: "Could not create new Account"))
        }

        instructions.append(
            SystemProgram.createAccountInstruction(
                from: fromAccount,
                toNewPubkey: newAccount.publicKey,
                lamports: amount + minimumBalanceForRentExemption
            )
        )

        instructions.append(
            TokenProgram.initializeAccountInstruction(
                account: newAccount.publicKey,
                mint: .wrappedSOLMint,
                owner: payer
            )
        )

        cleanupInstructions.append(
            TokenProgram.closeAccountInstruction(
                account: newAccount.publicKey,
                destination: payer,
                owner: payer
            )
        )

        signers.append(newAccount)

        return .success(newAccount)
    }

    private func createAccountByMint(
        owner: PublicKey,
        mint: PublicKey,
        instructions: inout [TransactionInstruction],
        cleanupInstructions: inout [TransactionInstruction],
        signers: inout [Account],
        minimumBalanceForRentExemption: UInt64
    ) -> Result<Account, Error> {
        guard let newAccount = Account(network: self.router.endpoint.network) else {
            return .failure(SolanaError.invalidRequest(reason: "Could not create new Account"))
        }

        instructions.append(
            SystemProgram.createAccountInstruction(
                from: owner,
                toNewPubkey: newAccount.publicKey,
                lamports: minimumBalanceForRentExemption
            )
        )

        instructions.append(
            TokenProgram.initializeAccountInstruction(
                account: newAccount.publicKey,
                mint: mint,
                owner: owner
            )
        )

        if mint == .wrappedSOLMint {
            cleanupInstructions.append(
                TokenProgram.closeAccountInstruction(
                    account: newAccount.publicKey,
                    destination: owner,
                    owner: owner
                )
            )
        }

        signers.append(newAccount)
        return .success(newAccount)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func swap(
        account: Account? = nil,
        pool: Pool? = nil,
        source: PublicKey,
        sourceMint: PublicKey,
        destination: PublicKey? = nil,
        destinationMint: PublicKey,
        slippage: Double,
        amount: UInt64
    ) async throws -> SwapResponse {
        try await withCheckedThrowingContinuation { c in
            self.swap(
                account: account,
                pool: pool,
                source: source,
                sourceMint: sourceMint,
                destination: destination,
                destinationMint: destinationMint,
                slippage: slippage,
                amount: amount,
                onComplete: c.resume(with:)
            )
        }
    }
    func getAccountInfoData(account: String, tokenProgramId: PublicKey) async throws -> AccountInfo {
        try await withCheckedThrowingContinuation { c in
            self.getAccountInfoData(account: account, tokenProgramId: tokenProgramId, onComplete: c.resume(with:))
        }
    }
}

extension ActionTemplates {
    public struct Swap: ActionTemplate {
        public init(account: Account? = nil,
                    pool: Pool? = nil,
                    source: PublicKey,
                    sourceMint: PublicKey,
                    destination: PublicKey? = nil,
                    destinationMint: PublicKey,
                    slippage: Double,
                    amount: UInt64) {
            self.account = account
            self.pool = pool
            self.source = source
            self.sourceMint = sourceMint
            self.destination = destination
            self.destinationMint = destinationMint
            self.slippage = slippage
            self.amount = amount
        }

        public let account: Account?// = nil
        public let pool: Pool?// = nil
        public let source: PublicKey
        public let sourceMint: PublicKey
        public let destination: PublicKey?// = nil
        public let destinationMint: PublicKey
        public let slippage: Double
        public let amount: UInt64

        public typealias Success = Action.SwapResponse

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Action.SwapResponse, Error>) -> Void) {
            actionClass.swap(account: account,
                             pool: pool,
                             source: source,
                             sourceMint: sourceMint,
                             destination: destination,
                             destinationMint: destinationMint,
                             slippage: slippage,
                             amount: amount,
                             onComplete: completion)
        }
    }

    public struct GetAccountInfoData: ActionTemplate {
        public init(account: String, tokenProgramId: PublicKey) {
            self.account = account
            self.tokenProgramId = tokenProgramId
        }


        public let account: String
        public let tokenProgramId: PublicKey

        public typealias Success = AccountInfo

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<AccountInfo, Error>) -> Void) {
            actionClass.getAccountInfoData(account: account, tokenProgramId: tokenProgramId, onComplete: completion)
        }
    }
}
