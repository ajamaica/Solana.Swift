import Foundation
import RxSwift

extension Solana {
    /*public func getTokenWallets(account: String? = nil) -> Single<[Wallet]> {
        Single.create { emitter in
            self.getTokenWallets(account: account) { result in
                switch result {
                case .success(let wallets):
                    return emitter(.success(wallets))
                case .failure(let error):
                    return emitter(.failure(error))
                }
            }
            return Disposables.create()
        }
    }*/
    public func getTokenWallets(account: String? = nil) -> Single<[Wallet]> {
            guard let account = account ?? accountStorage.account?.publicKey.base58EncodedString else {
                return .error(SolanaError.unauthorized)
            }
            let memcmp = EncodableWrapper(
                wrapped:
                    ["offset": EncodableWrapper(wrapped: 32),
                     "bytes": EncodableWrapper(wrapped: account)]
            )
            let configs = RequestConfiguration(commitment: "recent", encoding: "base64", dataSlice: nil, filters: [
                ["memcmp": memcmp],
                ["dataSize": .init(wrapped: 165)]
            ])
            return getProgramAccounts(
                publicKey: PublicKey.tokenProgramId.base58EncodedString,
                configs: configs,
                decodedTo: AccountInfo.self
            )
            .map {
                $0.compactMap {$0.account.data.value != nil ? $0: nil}
            }
            .map {$0.map {($0.pubkey, $0.account.data.value!)}}
            .map {
                $0.map { (pubkey, accountInfo) in
                    let mintAddress = accountInfo.mint.base58EncodedString
                    let token = self.supportedTokens.first(where: {$0.address == mintAddress}) ?? .unsupported(mint: mintAddress)
                    
                    return Wallet(
                        pubkey: pubkey,
                        lamports: accountInfo.lamports,
                        token: token,
                        liquidity: false
                    )
                }
            }
        }
}
