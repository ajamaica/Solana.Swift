import XCTest
import Solana

@available(iOS 13.0, *)
@available(macOS 10.15, *)
class getTokenWallets: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var account: Account { try! solana.auth.account.get() }

    override func setUpWithError() throws {
        let wallet: TestsWallet = .getWallets
        solana = Solana(router: NetworkingRouter(endpoint: endpoint), accountStorage: InMemoryAccountStorage())
        let account = Account(phrase: wallet.testAccount.components(separatedBy: " "), network: endpoint.network)!
        try solana.auth.save(account).get()
    }
    
    func testsGetTokenWalletsParsing() throws {
        let jsonData = getFileFrom("TokenInfo/getTokenWallets")

        let wallets = try JSONDecoder().decode(Response<Rpc<[TokenAccount<AccountInfoData>]>>.self, from: jsonData)
        XCTAssertNotNil(wallets.result?.value)
        XCTAssertNotEqual(wallets.result!.value.count, 0)
    }
    
    func testsGetTokenWallets() async throws {
        let wallets = try await solana.action.getTokenWallets()
        XCTAssertFalse(wallets.isEmpty)
    }
}
