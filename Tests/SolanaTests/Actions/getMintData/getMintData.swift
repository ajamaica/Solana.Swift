import XCTest
@testable import Solana

@available(iOS 13.0, *)
@available(macOS 10.15, *)
class getMintData: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var account: Account { try! solana.auth.account.get() }

    override func setUpWithError() throws {
        let wallet: TestsWallet = .devnet
        solana = Solana(router: NetworkingRouter(endpoint: endpoint), accountStorage: InMemoryAccountStorage())
        let account = Account(phrase: wallet.testAccount.components(separatedBy: " "), network: endpoint.network)!
        try solana.auth.save(account).get()
    }
    
    func testGetMintData() async throws {
        let data: Mint? = try await solana.action.getMintData(mintAddress: PublicKey(string: "8wzZaGf89zqx7PRBoxk9T6QyWWQbhwhdU555ZxRnceG3")!)
        XCTAssertNotNil(data)
    }
    
    func testGetMultipleMintDatas() async throws {
        let datas: [PublicKey: Mint]? = try await solana.action.getMultipleMintDatas(mintAddresses: [PublicKey(string: "8wzZaGf89zqx7PRBoxk9T6QyWWQbhwhdU555ZxRnceG3")!])
        XCTAssertNotNil(datas)
    }
    
    func testGetPools() async throws {
        let pools: [Pool]? = try await solana.action.getSwapPools()
        XCTAssertNotNil(pools)
        XCTAssertNotEqual(pools!.count, 0)
    }

    func testMintToInstruction() {
        let publicKey = PublicKey(string: "11111111111111111111111111111111")!
        let instruction = TokenProgram.mintToInstruction(tokenProgramId: publicKey, mint: publicKey, destination: publicKey, authority: publicKey, amount: 1000000000)
        XCTAssertEqual("6AsKhot84V8s", Base58.encode(instruction.data))
    }
}
