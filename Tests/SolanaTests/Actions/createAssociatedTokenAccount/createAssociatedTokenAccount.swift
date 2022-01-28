import XCTest
import Solana

@available(iOS 13.0, *)
@available(macOS 10.15, *)
class createAssociatedTokenAccount: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var account: Account { try! solana.auth.account.get() }
    
    override func setUp() async throws {
        let wallet: TestsWallet = .devnet
        solana = Solana(router: NetworkingRouter(endpoint: endpoint), accountStorage: InMemoryAccountStorage())
        let account = Account(phrase: wallet.testAccount.components(separatedBy: " "), network: endpoint.network)!
        _ = solana.auth.save(account)
    }
    
    func testGetOrCreateAssociatedTokenAccount() async throws {
        let tokenMint = PublicKey(string: "2tWC4JAdL4AxEFJySziYJfsAnW2MHKRo98vbAPiRDSk8")!
        let account: (transactionId: TransactionID?, associatedTokenAddress: PublicKey)? = try await solana.action.getOrCreateAssociatedTokenAccount(owner: try solana.auth.account.get().publicKey, tokenMint: tokenMint)
        XCTAssertNotNil(account)
    }
    
    func testFailCreateAssociatedTokenAccountItExisted() async throws {
        let tokenMint = PublicKey(string: "2tWC4JAdL4AxEFJySziYJfsAnW2MHKRo98vbAPiRDSk8")!
        await asyncAssertThrowing("Should fail to create associated token account if existed") {
            try await (solana.action.createAssociatedTokenAccount(for: try solana.auth.account.get().publicKey, tokenMint: tokenMint) as TransactionID?)
        }

    }

    func testFindAssociatedTokenAddress() {
        let associatedTokenAddress = try! PublicKey.associatedTokenAddress(
            walletAddress: PublicKey(string: "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG")!,
            tokenMintAddress: PublicKey(string: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")!
        ).get()

        XCTAssertEqual(associatedTokenAddress.base58EncodedString, "3uetDDizgTtadDHZzyy9BqxrjQcozMEkxzbKhfZF4tG3")
    }
}
