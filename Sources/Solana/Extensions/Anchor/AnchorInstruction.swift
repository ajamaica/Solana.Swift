import Foundation

public struct AnchorPda {
    public let address: PublicKey
    public let bump: UInt8
}

extension PublicKey {
    public static func findAnchorPda(anchorSeed: Data, programId: PublicKey) -> Result<AnchorPda, Error> {
        findProgramAddress(
            seeds: [anchorSeed],
            programId: programId)
            .map { (address, bump) in
                AnchorPda(address: address, bump: bump)
            }
    }
}

extension Account.Meta {
    public init(anchorPda: AnchorPda, isWritable: Bool) {
        self.init(publicKey: anchorPda.address, isSigner: false, isWritable: isWritable)
    }
}

public protocol AnchorInstruction: BorshSerializable {
    var methodName: String { get }
}

extension TransactionInstruction {
    public init?(accounts: [Account.Meta], programId: PublicKey, anchorInstruction: AnchorInstruction) {
        var instructionData = Data()
        let instructionHash = sha256(data: "global:\(anchorInstruction.methodName)".data(using: .utf8)!)
        instructionData.append(instructionHash.subdata(in: 0..<8))
        do {
            try anchorInstruction.serialize(to: &instructionData)
            self.init(keys: accounts, programId: programId, data: [instructionData])
        } catch {
            return nil
        }
    }
}
