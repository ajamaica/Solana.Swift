//
//  File.swift
//  
//
//  Created by Hadrien Mazelier (Perso) on 11.01.22.
//

import Foundation
import XCTest

func asyncAssertThrowing<Out>(_ message: String, file: StaticString = #file, line: UInt = #line, block: () async throws -> Out) async {
    do {
        _ = try await block()
        XCTFail(message, file: file, line: line)
    } catch {}
}
