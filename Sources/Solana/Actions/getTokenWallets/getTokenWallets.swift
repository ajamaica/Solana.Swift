import Foundation

extension Action {
    public func getTokenWallets(account: String? = nil, onComplete: @escaping ((Result<[Wallet], Error>) -> Void)) {

        guard let account = try? account ?? auth.account.get().publicKey.base58EncodedString else {
            return onComplete(.failure(SolanaError.unauthorized))
        }

        let configs = RequestConfiguration(commitment: "recent", encoding: "jsonParsed")

        ContResult.init { cb in
            self.api.getTokenAccountsByOwner(pubkey: account, programId: PublicKey.tokenProgramId.base58EncodedString, configs: configs )
            { (result: Result<[TokenAccount<AccountInfoData>], Error>) in cb(result) }
        }.map { accounts in
            let accountsValues = accounts.compactMap { $0.account.data.value != nil ? $0: nil }
            let pubkeyValue = accountsValues.map { ($0.pubkey, $0.account.data.value!) }
            let wallets = pubkeyValue.map { (pubkey, accountInfo) -> Wallet in
                let mintAddress = accountInfo.parsed.info.mint
                let token = self.supportedTokens.first(where: {$0.address == mintAddress}) ?? Token(address: mintAddress)
                return Wallet(pubkey: pubkey, ammount: accountInfo.parsed.info.tokenAmount, token: token, liquidity: false)
            }
            return wallets
        }.run(onComplete)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Action {
    func getTokenWallets(account: String? = nil) async throws -> [Wallet] {
        try await withCheckedThrowingContinuation { c in
            self.getTokenWallets(account: account, onComplete: c.resume(with:))
        }
    }
}


extension ActionTemplates {
    public struct GetTokenWallets: ActionTemplate {
        public init(account: String? = nil) {
            self.account = account
        }

        public typealias Success = [Wallet]
        public let account: String?

        public func perform(withConfigurationFrom actionClass: Action, completion: @escaping (Result<[Wallet], Error>) -> Void) {
            actionClass.getTokenWallets(account: account, onComplete: completion)
        }
    }
}


public struct AccountInfoData: BufferLayout {
    public static var BUFFER_LENGTH: UInt64 = 0;
    
    public func serialize(to writer: inout Data) throws {
        throw BufferLayoutError.NotImplemented
    }
    
    public init(from reader: inout BinaryReader) throws {
        throw BufferLayoutError.NotImplemented
    }
    public let space: Int;
    public let program: String;
    public let parsed: AccountParsedContent;
}

public struct AccountParsedContent: Codable {
    public let type: String;
    public let accountType: String?;
    public let info: AccountParsedContentInfo
}

public struct AccountParsedContentInfo: Codable {
    public let tokenAmount: TokenAmount;
    public let delegate: String?;
    public let delegatedAmount: TokenAmount?;
    public let owner: String;
    public let mint: String;
    public let isNative: Bool;
    public let state: String;
    
}
