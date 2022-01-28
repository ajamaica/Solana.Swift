import XCTest
import Solana

@available(iOS 13.0, *)
@available(macOS 10.15, *)
class createTokenAccount: XCTestCase {
    var endpoint = RPCEndpoint.devnetSolana
    var solana: Solana!
    var account: Account { try! solana.auth.account.get() }

    override func setUpWithError() throws {
        let wallet: TestsWallet = .devnet
        solana = Solana(router: NetworkingRouter(endpoint: endpoint), accountStorage: InMemoryAccountStorage())
        let account = Account(phrase: wallet.testAccount.components(separatedBy: " "), network: endpoint.network)!
        try solana.auth.save(account).get()
    }
    
    func testCreateTokenAccount() async throws {
        let mintAddress = "6AUM4fSvCAxCugrbJPFxTqYFp9r3axYx973yoSyzDYVH"
        let account: (signature: String, newPubkey: String)? = try await solana.action.createTokenAccount( mintAddress: mintAddress)
        XCTAssertNotNil(account)
    }
    
    func testCreateAccountInstruction() {
        let instruction = SystemProgram.createAccountInstruction(from: PublicKey.programId, toNewPubkey: PublicKey.programId, lamports: 2039280, space: 165, programPubkey: PublicKey.programId)
        
        XCTAssertEqual("11119os1e9qSs2u7TsThXqkBSRUo9x7kpbdqtNNbTeaxHGPdWbvoHsks9hpp6mb2ed1NeB", Base58.encode(instruction.data))
    }
}
