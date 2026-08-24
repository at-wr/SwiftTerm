#if canImport(UIKit)
import Testing
import UIKit
@testable import SwiftTerm

@MainActor
@Suite("iOS semantic simulated keys")
struct IOSSimulatedKeyInputTests {
    private final class CapturingDelegate: TerminalViewDelegate {
        var packets = [[UInt8]]()

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            packets.append(Array(data))
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
        let delegate = CapturingDelegate()
        view.terminalDelegate = delegate
        return (view, delegate)
    }

    @Test("unmodified cursor keys follow live DECCKM while modified keys use CSI parameters")
    func applicationCursorAndModifiers() {
        let (view, delegate) = makeView()

        #expect(view.sendSimulatedKey(.up))
        view.feed(text: "\u{1B}[?1h")
        #expect(view.sendSimulatedKey(.up))
        #expect(view.sendSimulatedKey(.up, modifiers: [.shift]))
        #expect(view.sendSimulatedKey(.f5, modifiers: [.alt, .ctrl]))
        #expect(view.sendSimulatedKey(.f12, modifiers: [.shift, .alt, .ctrl]))

        #expect(delegate.packets == [
            Array("\u{1B}[A".utf8),
            Array("\u{1B}OA".utf8),
            Array("\u{1B}[1;2A".utf8),
            Array("\u{1B}[15;7~".utf8),
            Array("\u{1B}[24;8~".utf8),
        ])
    }

    @Test("Tab and explicit text use the encoder's legacy compatibility rules")
    func legacyControlAndTextKeys() {
        let (view, delegate) = makeView()

        #expect(view.sendSimulatedKey(.tab, modifiers: [.shift]))
        #expect(view.sendSimulatedKey(.tab, modifiers: [.shift, .alt]))
        #expect(view.sendSimulatedKey(.text("\\"), modifiers: [.ctrl]))
        #expect(view.sendSimulatedKey(.text("|"), modifiers: [.ctrl]))
        #expect(view.sendSimulatedKey(.text("/"), modifiers: [.ctrl, .shift]))

        #expect(delegate.packets == [
            Array("\u{1B}[Z".utf8),
            Array("\u{1B}\u{1B}[Z".utf8),
            [28],
            Array("|".utf8),
            Array("\u{1B}[47;6u".utf8),
        ])
    }

    @Test("negotiated Kitty flags immediately change the same semantic key")
    func negotiatedKittyMode() {
        let (view, delegate) = makeView()
        view.feed(text: "\u{1B}[>1u")

        #expect(view.sendSimulatedKey(.tab, modifiers: [.shift]))
        #expect(delegate.packets == [Array("\u{1B}[9;2u".utf8)])
    }

    @Test("simulated text refuses bulk and multi-scalar injection")
    func textBoundary() {
        let (view, delegate) = makeView()

        #expect(!view.sendSimulatedKey(.text("")))
        #expect(!view.sendSimulatedKey(.text("ab")))
        #expect(!view.sendSimulatedKey(.text("e\u{301}")))
        #expect(delegate.packets.isEmpty)
    }
}
#endif
