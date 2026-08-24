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

    @Test("Shift, Option and Control use xterm modifier parameters")
    func modifiedCursorEditingAndFunctionKeys() {
        let cases: [(UIKeyboardHIDUsage, UIKeyModifierFlags, Bool, String)] = [
            (.keyboardUpArrow, .shift, false, "\u{1b}[1;2A"),
            (.keyboardDownArrow, .control, false, "\u{1b}[1;5B"),
            (.keyboardHome, [.shift, .control], false, "\u{1b}[1;6H"),
            (.keyboardEnd, .alternate, true, "\u{1b}[1;3F"),
            (.keyboardInsert, .shift, false, "\u{1b}[2;2~"),
            (.keyboardDeleteForward, .control, false, "\u{1b}[3;5~"),
            (.keyboardPageUp, [.alternate, .control], true, "\u{1b}[5;7~"),
            (.keyboardPageDown, [.shift, .alternate, .control], true, "\u{1b}[6;8~"),
            (.keyboardF1, .shift, false, "\u{1b}[1;2P"),
            (.keyboardF3, [.shift, .control], false, "\u{1b}[1;6R"),
            (.keyboardF5, .alternate, true, "\u{1b}[15;3~"),
            (.keyboardF12, [.shift, .alternate, .control], true, "\u{1b}[24;8~"),
        ]

        for (keyCode, flags, includeAlternate, expected) in cases {
            #expect(
                TerminalView.legacyModifiedKeySequence(
                    for: keyCode,
                    modifierFlags: flags,
                    includeAlternate: includeAlternate
                ) == Array(expected.utf8)
            )
        }
    }

    @Test("unmodified, composed Option and Command stay outside xterm modifier encoding")
    func localAndTextModifierOwnershipIsPreserved() {
        #expect(TerminalView.legacyModifiedKeySequence(
            for: .keyboardUpArrow,
            modifierFlags: [],
            includeAlternate: true
        ) == nil)
        #expect(TerminalView.legacyModifiedKeySequence(
            for: .keyboardUpArrow,
            modifierFlags: .alternate,
            includeAlternate: false
        ) == nil)
        #expect(TerminalView.legacyModifiedKeySequence(
            for: .keyboardUpArrow,
            modifierFlags: [.command, .shift],
            includeAlternate: true
        ) == nil)

        #expect(TerminalView.shouldYieldLegacyKeyToUIKit(
            modifierFlags: [.command, .shift],
            charactersIgnoringModifiers: UIKeyCommand.inputUpArrow
        ))
        #expect(!TerminalView.shouldYieldLegacyKeyToUIKit(
            modifierFlags: [.command, .alternate],
            charactersIgnoringModifiers: "o"
        ))
    }
}
#endif
