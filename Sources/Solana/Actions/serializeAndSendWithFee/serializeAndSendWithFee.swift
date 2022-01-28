import Foundation

extension Action {
    fileprivate func retryOrError(instructions: [TransactionInstruction],
                                  recentBlockhash: String? = nil,
                                  signers: [Account],
                                  maxAttempts: Int = 3,
                                  numberOfTries: Int = 0,
                                  error: Error,
                                  onComplete: @escaping ((Result<String, Error>) -> Void)) {
        var numberOfTries = numberOfTries
        if numberOfTries <= maxAttempts,
           let error = error as? SolanaError {
            if case SolanaError.blockHashNotFound = error {
                numberOfTries += 1
                self.serializeAndSendWithFee(instructions: instructions,
                                             signers: signers,
                                             maxAttemps: maxAttempts,
                                             numberOfTries: numberOfTries,
                                             onComplete: onComplete)
                return
            }
        }
        onComplete(.failure(error))
        return
    }

    // Fixes typo, eventually the deprecation can be removed.
    @available(*, renamed: "serializeAndSendWithFee(instructions:recentBlockhash:signers:maxAttempts:)")
    public func serializeAndSendWithFee(
        instructions: [TransactionInstruction],
        recentBlockhash: String? = nil,
        signers: [Account],
        maxAttemps: Int,
        numberOfTries: Int,
        onComplete: @escaping ((Result<String, Error>) -> Void)
    ) {
        serializeAndSendWithFee(
            instructions: instructions,
            recentBlockhash: recentBlockhash,
            signers: signers,
            maxAttempts: maxAttemps,
            numberOfTries: numberOfTries,
            onComplete: onComplete)
    }

    public func serializeAndSendWithFee(
        instructions: [TransactionInstruction],
        recentBlockhash: String? = nil,
        signers: [Account],
        maxAttempts: Int = 3,
        numberOfTries: Int = 0,
        onComplete: @escaping ((Result<String, Error>) -> Void)
    ) {

        ContResult.init { cb in
            self.serializeTransaction(instructions: instructions, recentBlockhash: recentBlockhash, signers: signers) {
                cb($0)
            }
        }.flatMap { transaction in
            return ContResult.init { cb in
                self.api.sendTransaction(serializedTransaction: transaction) {
                    cb($0)
                }
            }
        }.recover { error in
            var numberOfTries = numberOfTries
            if numberOfTries <= maxAttempts,
               let error = error as? SolanaError {
                if case SolanaError.blockHashNotFound = error {
                    numberOfTries += 1
                    return ContResult.init { cb in
                        self.serializeAndSendWithFee(instructions: instructions,
                                                     signers: signers,
                                                     maxAttempts: maxAttempts,
                                                     numberOfTries: numberOfTries,
                                                     onComplete: cb)
                    }
                }
            }
            return .failure(error)
        }
        .run(onComplete)
    }
}
extension Action {
    fileprivate func retrySimulateOrError(instructions: [TransactionInstruction],
                                          recentBlockhash: String? = nil,
                                          signers: [Account],
                                          maxAttempts: Int = 3,
                                          numberOfTries: Int = 0,
                                          error: (Error),
                                          onComplete: @escaping ((Result<String, Error>) -> Void)) {
        var numberOfTries = numberOfTries
        if numberOfTries <= maxAttempts,
           let error = error as? SolanaError {
            if case SolanaError.blockHashNotFound = error {
                numberOfTries += 1
                self.serializeAndSendWithFeeSimulation(instructions: instructions,
                                                       signers: signers,
                                                       maxAttemps: maxAttempts,
                                                       numberOfTries: numberOfTries,
                                                       onComplete: onComplete)
                return
            }
        }
        onComplete(.failure(error))
        return
    }

    // Fixes typo, eventually the deprecation can be removed.
    @available(*, renamed: "serializeAndSendWithFeeSimulation(instructions:recentBlockhash:signers:maxAttempts:)")
    public func serializeAndSendWithFeeSimulation(
        instructions: [TransactionInstruction],
        recentBlockhash: String? = nil,
        signers: [Account],
        maxAttemps: Int,
        numberOfTries: Int,
        onComplete: @escaping ((Result<String, Error>) -> Void)) {
        serializeAndSendWithFeeSimulation(instructions: instructions, recentBlockhash: recentBlockhash, signers: signers, maxAttempts: maxAttemps, numberOfTries: numberOfTries, onComplete: onComplete)
    }

    public func serializeAndSendWithFeeSimulation(
        instructions: [TransactionInstruction],
        recentBlockhash: String? = nil,
        signers: [Account],
        maxAttempts: Int = 3,
        numberOfTries: Int = 0,
        onComplete: @escaping((Result<String, Error>) -> Void)
    ) {
        serializeTransaction(instructions: instructions, recentBlockhash: recentBlockhash, signers: signers) { result in
            switch result {
            case .success(let transaction):
                self.api.simulateTransaction(transaction: transaction) {
                    switch $0 {
                    case .success(let r):
                        if r.err != nil {
                            onComplete(.failure(SolanaError.other("Simulation error")))
                        }
                        onComplete(.success("SIMULATED_TRANSATION"))
                        return
                    case .failure(let error):
                        self.retrySimulateOrError(instructions: instructions,
                                                    recentBlockhash: recentBlockhash,
                                                    signers: signers,
                                                    maxAttempts: maxAttempts,
                                                    numberOfTries: numberOfTries,
                                                    error: error,
                                                    onComplete: onComplete)
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
    func serializeAndSendWithFee(
        instructions: [TransactionInstruction],
        recentBlockhash: String? = nil,
        signers: [Account],
        maxAttempts: Int = 3,
        numberOfTries: Int = 0
    ) async throws -> String {
        try await withCheckedThrowingContinuation { c in
            self.serializeAndSendWithFee(
                instructions: instructions,
                recentBlockhash: recentBlockhash,
                signers: signers,
                maxAttempts: maxAttempts,
                numberOfTries: numberOfTries,
                onComplete: c.resume(with:)
            )
        }
    }
    
    func serializeAndSendWithFeeSimulation(
        instructions: [TransactionInstruction],
        recentBlockhash: String? = nil,
        signers: [Account],
        maxAttempts: Int = 3,
        numberOfTries: Int = 0
    ) async throws -> String {
        try await withCheckedThrowingContinuation { c in
            self.serializeAndSendWithFeeSimulation(
                instructions: instructions,
                recentBlockhash: recentBlockhash,
                signers: signers,
                maxAttempts: maxAttempts,
                numberOfTries: numberOfTries,
                onComplete: c.resume(with:)
            )
        }
    }
}

extension ActionTemplates {
    public struct SerializeAndSendWithFee: ActionTemplate {
        public init(instructions: [TransactionInstruction], signers: [Account], recentBlockhash: String? = nil, maxAttempts: Int = 3) {
            self.instructions = instructions
            self.signers = signers
            self.recentBlockhash = recentBlockhash
            self.maxAttempts = maxAttempts
        }

        public let instructions: [TransactionInstruction]
        public let recentBlockhash: String?
        public let signers: [Account]
        public let maxAttempts: Int

        public typealias Success = String

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Success, Error>) -> Void) {
            actionClass.serializeAndSendWithFee(instructions: instructions, recentBlockhash: recentBlockhash, signers: signers, maxAttempts: maxAttempts, numberOfTries: 0, onComplete: completion)
        }
    }

    public struct SerializeAndSendWithFeeSimulation: ActionTemplate {
        public init(instructions: [TransactionInstruction], signers: [Account], recentBlockhash: String? = nil, maxAttempts: Int = 3) {
            self.instructions = instructions
            self.signers = signers
            self.recentBlockhash = recentBlockhash
            self.maxAttempts = maxAttempts
        }

        public let instructions: [TransactionInstruction]
        public let recentBlockhash: String?
        public let signers: [Account]
        public let maxAttempts: Int

        public typealias Success = String

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<Success, Error>) -> Void) {
            actionClass.serializeAndSendWithFeeSimulation(instructions: instructions, recentBlockhash: recentBlockhash, signers: signers, maxAttempts: maxAttempts, numberOfTries: 0, onComplete: completion)
        }
    }
}
