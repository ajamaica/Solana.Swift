# Solana.Swift
[![Swift](https://github.com/ajamaica/Solana.Swift/actions/workflows/swift.yml/badge.svg?branch=master)](https://github.com/ajamaica/Solana.Swift/actions/workflows/swift.yml)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.png?v=103)](https://opensource.org/licenses/mit-license.php)  
[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat&colorA=28a745&&colorB=4E4E4E)](https://github.com/apple/swift-package-manager)

This is a open source library on pure swift for Solana protocol.

The objective is to create a cross platform, fully functional, highly tested and less depencies as posible. 

Please check my wallet [Summer](https://github.com/ajamaica/Summer).

# Features
- [x] Sign and send transactions.
- [x] Key pair generation
- [x] RPC configuration.
- [x] SPM integration
- [x] Few libraries requirement (TweetNACL, Starscream, secp256k1).
- [x] Fully tested (53%)
- [x] Sockets
- [ ] Type-safe Transaction templates
- [ ] Documentation with guides and examples
- [ ] Program template library for common tasks
- [x] Helpers to assist with Anchor Instructions

# Usage

### Initialization
Set the NetworkingRouter and setup your enviroment. You can also pass your own **URLSession** with your own settings. Use this router to initialize the sdk with an object that conforms the SolanaAccountStorage protocol
```swift
let network = NetworkingRouter(endpoint: .devnetSolana)
let solana = Solana(router: network, accountStorage: self.accountStorage)
```
### Keypair generation

SolanaAccountStorage interface is used to return the generated accounts. The actual storage of the accout is handled by the client. Please make sure this account is stored correctly (you can encrypt it on the keychain). The retrived accout is Serializable. Inside Account you will fine the phrase, publicKey and secretKey.

Example using Memory (NOT RECOMEMDED).
```swift
class InMemoryAccountStorage: SolanaAccountStorage {
    
    private var _account: Account?
    func save(_ account: Account) -> Result<Void, Error> {
        _account = account
        return .success(())
    }
    var account: Result<Account, Error> {
        if let account = _account {
            return .success(account)
        }
        return .failure(SolanaError.unauthorized)
    }
    func clear() -> Result<Void, Error> {
        _account = nil
        return .success(())
    }
}
```

Example using KeychainSwift.
```swift
enum SolanaAccountStorageError: Error {
    case unauthorized
}
struct KeychainAccountStorageModule: SolanaAccountStorage {
    private let tokenKey = "Summer"
    private let keychain = KeychainSwift()
    
    func save(_ account: Account) -> Result<Void, Error> {
        do {
            let data = try JSONEncoder().encode(account)
            keychain.set(data, forKey: tokenKey)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    var account: Result<Account, Error> {
        // Read from the keychain
        guard let data = keychain.getData(tokenKey) else { return .failure(SolanaAccountStorageError.unauthorized)  }
        if let account = try? JSONDecoder().decode(Account.self, from: data) {
            return .success(account)
        }
        return .failure(SolanaAccountStorageError.unauthorized)
    }
    func clear() -> Result<Void, Error> {
        keychain.clear()
        return .success(())
    }
}
```
### RPC api calls

We support [45](https://github.com/ajamaica/Solana.Swift/tree/master/Sources/Solana/Api "Check the Api folder") rpc api calls. If a call requires address in base58 format and it is null it will default to the one returned by SolanaAccountStorage.

Example using callback

Gets Accounts info.
```swift
solana.api.getAccountInfo(account: account.publicKey.base58EncodedString, decodedTo: AccountInfo.self) { result in
// process result
}
```
Gets Balance
```swift
 solana.api.getBalance(account: account.publicKey.base58EncodedString){ result in
 // process result
 }
```

### Actions

Actions are predifined program interfaces that construct the required inputs for the most common tasks in Solana ecosystems. You can see them as bunch of code that implements solana task using rpc calls.

We support 12.
- closeTokenAccount: Closes token account
- getTokenWallets: get token accounts
- createAssociatedTokenAccount: Opens associated token account
- sendSOL : Sends SOL native token
- createTokenAccount: Opens token account
- sendSPLTokens: Sends tokens
- findSPLTokenDestinationAddress : Finds address of a token of a address
- **serializeAndSendWithFee**: Serializes and signs the transaction. Then it it send to the blockchain.
- getMintData: Get mint data for token
- serializeTransaction: Serializes transaction
- getPools: Get all available pools. Very intensive
- swap: Swaps 2 tokens from pool.

#### Example

Create an account token

```swift
solana.action.createTokenAccount( mintAddress: mintAddress) { result in
// process
}
```
Sending sol
```swift
let toPublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
let transactionId = try! solana.action.sendSOL(
            to: toPublicKey,
            amount: 10
){ result in
 // process
}
```

### Anchor Helpers

Create your own structs that represents instructions of your anchor program; then create, sign, and send transactions to your program.

#### Example

Define your Anchor instruction

```swift
struct DepositFunds: AnchorInstruction {
    let userPdaBump: UInt8
    let bankPdaBump: UInt8
    let depositAmount: UInt64

    // MARK: - AnchorInstruction implementation

    public var methodName: String { "deposit_funds" } // Name of Rust function in Anchor program

    public func serialize(to writer: inout Data) throws {
        // serialize parameters to Rust function
        try userPdaBump.serialize(to: &writer)
        try bankPdaBump.serialize(to: &writer)
        try depositAmount.serialize(to: &writer)
    }
}
```

Construct and send a transaction from your instruction

```swift
solana.auth.account.onSuccess { account in
    guard let contractId = PublicKey(string: "<your_deployed_program_address>"),
          case let .success(userPda) = PublicKey.findAnchorPda(anchorSeed: account.publicKey.data, programId: contractId),
          case let .success(bankPda) = PublicKey.findAnchorPda(anchorSeed: "bank".data(using: .utf8)!, programId: contractId)
    else {
        return
    }

    let accounts = [
        Account.Meta(publicKey: account.publicKey, isSigner: true, isWritable: true),
        Account.Meta(anchorPda: userPda, isWritable: true),
        Account.Meta(anchorPda: bankPda, isWritable: true),
        Account.Meta(publicKey: PublicKey.programId, isSigner: false, isWritable: false),
    ]
    let instruction = DepositFunds(userPdaBump: userPda.bump, bankPdaBump: bankPda.bump, depositAmount: sol.toLamport(decimals: 9))
    guard let depositTx = TransactionInstruction(accounts: accounts,
                                                 programId: contractId,
                                                 anchorInstruction: instruction) else {
        // serialization threw
        return
    }

    solana.action.serializeAndSendWithFee(instructions: [depositTx], signers: [account]) { result in
        switch result {
        case .success(let txId): print("Success! \(txId)")
        case .failure(let err): print("Failed! \(err)")
        }
    }
}
```

## Requirements

- iOS 11.0+ / macOS 10.13+ / tvOS 11.0+ / watchOS 3.0+
- Swift 5.3+

## Installation

From Xcode 11, you can use [Swift Package Manager](https://swift.org/package-manager/) to add Solana.swift to your project.

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/ajamaica/Solana.Swift`
- Select "brach" with "master"
- Select Solana

If you encounter any problem or have a question on adding the package to an Xcode project, I suggest reading the [Adding Package Dependencies to Your App](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)  guide article from Apple.

### Acknowledgment

This was originally based on [P2P-ORG](https://github.com/p2p-org/solana-swift), currently is not longer compatible.
