import XCTest
import Solana

@available(iOS 13.0, *)
@available(macOS 10.15, *)
class sendSOL: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var account: Account { try! solana.auth.account.get() }

    override func setUpWithError() throws {
        let wallet: TestsWallet = .getWallets
        solana = Solana(router: NetworkingRouter(endpoint: endpoint), accountStorage: InMemoryAccountStorage())
        let account = Account(phrase: wallet.testAccount.components(separatedBy: " "), network: endpoint.network)!
        try solana.auth.save(account).get()
    }
    
    func testSendSOLFromBalance() async throws {
        let toPublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"

        let balance = try await solana.api.getBalance(account: nil, commitment: nil)
        XCTAssertNotNil(balance)

        let transactionId = try await solana.action.sendSOL(
            to: toPublicKey,
            amount: balance/10
        )
        XCTAssertNotNil(transactionId)
    }
    
    func testSendSOL() async throws {
        let toPublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
        let transactionId = try await solana.action.sendSOL(
            to: toPublicKey,
            amount: 0.001.toLamport(decimals: 9)
        )
        XCTAssertNotNil(transactionId)
    }
    func testSendSOLIncorrectDestination() async {
        let toPublicKey = "XX"
        await asyncAssertThrowing("sendSOL should fail when destination is incorrect") {
            try await solana.action.sendSOL(
                to: toPublicKey,
                amount: 0.001.toLamport(decimals: 9)
            )
        }
    }
    func testSendSOLBigAmmount() async {
        let toPublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
        await asyncAssertThrowing("sendSOL should fail when amount is too big") {
            try await solana.action.sendSOL(
                to: toPublicKey,
                amount: 9223372036854775808
            )
        }

    }
}
