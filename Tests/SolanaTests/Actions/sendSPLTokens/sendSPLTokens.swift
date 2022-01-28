import XCTest
import Solana

@available(iOS 13.0, *)
@available(macOS 10.15, *)
class sendSPLTokens: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var account: Account { try! solana.auth.account.get() }

    override func setUp() async throws {
        let wallet: TestsWallet = .devnet
        solana = Solana(router: NetworkingRouter(endpoint: endpoint), accountStorage: InMemoryAccountStorage())
        let account = Account(phrase: wallet.testAccount.components(separatedBy: " "), network: endpoint.network)!
        try solana.auth.save(account).get()
        _ = try await solana.api.requestAirdrop(account: account.publicKey.base58EncodedString, lamports: 100.toLamport(decimals: 9))
    }
    
    func testSendSPLTokenWithFee() async throws {
        let mintAddress = "6AUM4fSvCAxCugrbJPFxTqYFp9r3axYx973yoSyzDYVH"
        let source = "8hoBQbSFKfDK3Mo7Wwc15Pp2bbkYuJE8TdQmnHNDjXoQ"
        let destination = "8Poh9xusEcKtmYZ9U4FSfjrrrQR155TLWGAsyFWjjKxB"

        let transactionId = try await solana.action.sendSPLTokens(
            mintAddress: mintAddress,
            decimals: 5,
            from: source,
            to: destination,
            amount: Double(0.001).toLamport(decimals: 5)
        )
        XCTAssertNotNil(transactionId)
        
        let transactionIdB = try await solana.action.sendSPLTokens(
            mintAddress: mintAddress,
            decimals: 5,
            from: destination,
            to: source,
            amount: Double(0.001).toLamport(decimals: 5)
        )
        XCTAssertNotNil(transactionIdB)
    }
}
