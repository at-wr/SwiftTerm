#if canImport(UIKit)
import Testing
import UIKit
@testable import SwiftTerm

@MainActor
@Suite("iOS software modifier input")
struct IOSSoftwareModifierInputTests {
    private final class CapturingDelegate: TerminalViewDelegate {
        var sent: [UInt8] = []

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            sent.append(contentsOf: data)
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: TerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func scrolled(source: TerminalView, position: Double) {}
        func requestOpenLink(source: TerminalView, link: String, params: [String: String]) {}
        func bell(source: TerminalView) {}
        func clipboardCopy(source: TerminalView, content: Data) {}
        func clipboardRead(source: TerminalView) -> Data? { nil }
        func iTermContent(source: TerminalView, content: ArraySlice<UInt8>) {}
        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
    }

    private func makeView() -> (TerminalView, CapturingDelegate) {
        let view = TerminalView(frame: CGRect(x: 0, y: 0, width: 320, height: 160))
        // Exercise the public simulated-modifier path used by hosts with a
        // custom accessory, rather than SwiftTerm's built-in accessory state.
        view.inputAccessoryView = UIView()
        let delegate = CapturingDelegate()
        view.terminalDelegate = delegate
        return (view, delegate)
    }

    @Test("Meta Return uses the configured carriage-return sequence")
    func metaReturn() {
        let (view, delegate) = makeView()
        var resetCount = 0
        view.onSimulatedModifierReset = { resetCount += 1 }
        view.metaModifier = true

        view.insertText("\n")

        #expect(delegate.sent == [ControlCodes.ESC, ControlCodes.CR])
        #expect(!view.metaModifier)
        #expect(resetCount == 1)
    }

    @Test("Control and Meta combine for software-keyboard text")
    func controlMetaText() {
        let (view, delegate) = makeView()
        view.controlModifier = true
        view.metaModifier = true

        view.insertText("c")

        #expect(delegate.sent == [ControlCodes.ESC, 0x03])
        #expect(!view.controlModifier)
        #expect(!view.metaModifier)
    }

    @Test("Meta Backspace prefixes the configured legacy erase byte")
    func metaBackspace() {
        let (view, delegate) = makeView()
        view.metaModifier = true

        view.deleteBackward()

        #expect(delegate.sent == [ControlCodes.ESC, ControlCodes.DEL])
        #expect(!view.metaModifier)
    }

    @Test("Control Backspace uses BS and consumes the simulated modifier")
    func controlBackspace() {
        let (view, delegate) = makeView()
        view.controlModifier = true

        view.deleteBackward()

        #expect(delegate.sent == [ControlCodes.BS])
        #expect(!view.controlModifier)
    }

    @Test("Meta Return preserves a host-configured return byte sequence")
    func customMetaReturn() {
        let (view, delegate) = makeView()
        view.returnByteSequence = [ControlCodes.LF]
        view.metaModifier = true

        view.insertText("\n")

        #expect(delegate.sent == [ControlCodes.ESC, ControlCodes.LF])
    }
}
#endif
