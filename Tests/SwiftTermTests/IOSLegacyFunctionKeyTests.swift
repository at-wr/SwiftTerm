#if canImport(UIKit)
import Testing
import UIKit
@testable import SwiftTerm

@Suite("iOS legacy hardware keys")
struct IOSLegacyFunctionKeyTests {
    @Test("F1 through F12 map one-to-one onto the legacy sequence table")
    func allTwelveFunctionKeysAreDistinctAndComplete() {
        let keyCodes: [UIKeyboardHIDUsage] = [
            .keyboardF1, .keyboardF2, .keyboardF3, .keyboardF4,
            .keyboardF5, .keyboardF6, .keyboardF7, .keyboardF8,
            .keyboardF9, .keyboardF10, .keyboardF11, .keyboardF12,
        ]

        let sequences = keyCodes.map(TerminalView.legacyFunctionKeySequence(for:))
        #expect(sequences == EscapeSequences.cmdF.map(Optional.some))
        #expect(Set(sequences.compactMap { $0 }).count == keyCodes.count)
        #expect(TerminalView.legacyFunctionKeySequence(for: .keyboardF13) == nil)
    }

    @Test("Insert and forward Delete send their xterm editing sequences")
    func editingClusterKeysAreComplete() {
        #expect(
            TerminalView.legacyEditingKeySequence(for: .keyboardInsert)
                == EscapeSequences.cmdInsert
        )
        #expect(
            TerminalView.legacyEditingKeySequence(for: .keyboardDeleteForward)
                == EscapeSequences.cmdDelKey
        )
        #expect(TerminalView.legacyEditingKeySequence(for: .keyboardHome) == nil)
    }
}
#endif
