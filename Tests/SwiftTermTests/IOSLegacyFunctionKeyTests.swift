#if canImport(UIKit)
import Testing
import UIKit
@testable import SwiftTerm

@Suite("iOS legacy hardware keys")
struct IOSLegacyFunctionKeyTests {
    @Test("F1 through F20 map one-to-one onto the PC and VT220 sequence tables")
    func allTwentyFunctionKeysAreDistinctAndComplete() {
        let keyCodes: [UIKeyboardHIDUsage] = [
            .keyboardF1, .keyboardF2, .keyboardF3, .keyboardF4,
            .keyboardF5, .keyboardF6, .keyboardF7, .keyboardF8,
            .keyboardF9, .keyboardF10, .keyboardF11, .keyboardF12,
        ]

        let baseSequences = keyCodes.map(TerminalView.legacyFunctionKeySequence(for:))
        #expect(baseSequences == EscapeSequences.cmdF.map(Optional.some))

        let extendedKeyCodes: [UIKeyboardHIDUsage] = [
            .keyboardF13, .keyboardF14, .keyboardF15, .keyboardF16,
            .keyboardF17, .keyboardF18, .keyboardF19, .keyboardF20,
        ]
        let expectedExtended = [25, 26, 28, 29, 31, 32, 33, 34]
            .map { Array("\u{1b}[\($0)~".utf8) }
        let extendedSequences = extendedKeyCodes
            .compactMap(TerminalView.legacyFunctionKeySequence(for:))
        #expect(extendedSequences == expectedExtended)
        #expect(Set(baseSequences.compactMap { $0 } + extendedSequences).count == 20)
        #expect(TerminalView.legacyFunctionKeySequence(for: .keyboardF21) == nil)
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

    @Test("legacy Meta prefixes Tab, Backtab and Escape without stealing Command")
    func legacyControlKeysPreserveMeta() {
        let cases: [(UIKeyboardHIDUsage, UIKeyModifierFlags, Bool, Bool, String)] = [
            (.keyboardTab, [], false, false, "\t"),
            (.keyboardTab, .control, false, false, "\t"),
            (.keyboardTab, .shift, false, false, "\u{1b}[Z"),
            (.keyboardTab, .alternate, false, false, "\t"),
            (.keyboardTab, .alternate, true, false, "\u{1b}\t"),
            (.keyboardTab, [.control, .alternate], true, false, "\u{1b}\t"),
            (.keyboardTab, [.shift, .alternate], true, false, "\u{1b}\u{1b}[Z"),
            (.keyboardTab, [.shift, .control, .alternate], true, false, "\u{1b}\u{1b}[Z"),
            (.keyboardEscape, [], false, false, "\u{1b}"),
            (.keyboardEscape, [.shift, .control], false, false, "\u{1b}"),
            (.keyboardEscape, .alternate, true, false, "\u{1b}\u{1b}"),
            (.keyboardEscape, [], false, true, "\u{1b}\u{1b}"),
        ]

        for (keyCode, flags, includeAlternate, stickyMeta, expected) in cases {
            #expect(TerminalView.legacyControlKeySequence(
                for: keyCode,
                modifierFlags: flags,
                includeAlternate: includeAlternate,
                stickyMeta: stickyMeta
            ) == Array(expected.utf8))
        }

        #expect(TerminalView.legacyControlKeySequence(
            for: .keyboardTab,
            modifierFlags: [.command, .shift],
            includeAlternate: true,
            stickyMeta: false
        ) == nil)
        #expect(TerminalView.legacyControlKeySequence(
            for: .keyboardReturnOrEnter,
            modifierFlags: .alternate,
            includeAlternate: true,
            stickyMeta: false
        ) == nil)
    }

    @Test("legacy Shift-Return emits LF and preserves configured Meta")
    func legacyShiftReturn() {
        #expect(TerminalView.legacyShiftReturnSequence(
            for: .keyboardReturnOrEnter,
            modifierFlags: .shift,
            includeAlternate: false,
            stickyMeta: false
        ) == [ControlCodes.LF])
        #expect(TerminalView.legacyShiftReturnSequence(
            for: .keyboardReturnOrEnter,
            modifierFlags: [.shift, .control, .alternate],
            includeAlternate: true,
            stickyMeta: false
        ) == [ControlCodes.ESC, ControlCodes.LF])
        #expect(TerminalView.legacyShiftReturnSequence(
            for: .keyboardReturnOrEnter,
            modifierFlags: [.shift, .command],
            includeAlternate: true,
            stickyMeta: true
        ) == nil)
        #expect(TerminalView.legacyShiftReturnSequence(
            for: .keyboardTab,
            modifierFlags: .shift,
            includeAlternate: false,
            stickyMeta: false
        ) == nil)
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
            (.keyboardF13, .control, false, "\u{1b}[25;5~"),
            (.keyboardF20, [.shift, .alternate, .control], true, "\u{1b}[34;8~"),
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

    @Test("DECKPAM maps every physical numeric-keypad key and DECKPNM yields text to UIKit")
    func applicationKeypadModeIsCompleteAndReversible() {
        let cases: [(UIKeyboardHIDUsage, String)] = [
            (.keypadAsterisk, "\u{1b}Oj"),
            (.keypadPlus, "\u{1b}Ok"),
            (.keypadComma, "\u{1b}Ol"),
            (.keypadHyphen, "\u{1b}Om"),
            (.keypadPeriod, "\u{1b}On"),
            (.keypadSlash, "\u{1b}Oo"),
            (.keypad0, "\u{1b}Op"),
            (.keypad1, "\u{1b}Oq"),
            (.keypad2, "\u{1b}Or"),
            (.keypad3, "\u{1b}Os"),
            (.keypad4, "\u{1b}Ot"),
            (.keypad5, "\u{1b}Ou"),
            (.keypad6, "\u{1b}Ov"),
            (.keypad7, "\u{1b}Ow"),
            (.keypad8, "\u{1b}Ox"),
            (.keypad9, "\u{1b}Oy"),
            (.keypadEqualSign, "\u{1b}OX"),
            (.keypadEqualSignAS400, "\u{1b}OX"),
            (.keypadEnter, "\u{1b}OM"),
        ]

        let (terminal, _) = TerminalTestHarness.makeTerminal()
        #expect(!terminal.applicationKeypad)
        for (keyCode, _) in cases {
            #expect(TerminalView.legacyKeypadSequence(
                for: keyCode,
                applicationKeypad: terminal.applicationKeypad
            ) == nil)
        }

        terminal.feed(text: "\u{1b}=")
        #expect(terminal.applicationKeypad)
        for (keyCode, expected) in cases {
            #expect(TerminalView.legacyKeypadSequence(
                for: keyCode,
                applicationKeypad: terminal.applicationKeypad
            ) == Array(expected.utf8))
        }
        #expect(TerminalView.legacyKeypadSequence(
            for: .keypadNumLock,
            applicationKeypad: true
        ) == nil)

        terminal.feed(text: "\u{1b}>")
        #expect(!terminal.applicationKeypad)
        #expect(TerminalView.legacyKeypadSequence(
            for: .keypad1,
            applicationKeypad: terminal.applicationKeypad
        ) == nil)
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
