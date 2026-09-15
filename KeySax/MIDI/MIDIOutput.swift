import Foundation
import CoreMIDI

final class MIDIOutput: @unchecked Sendable {
    private var client = MIDIClientRef()
    private var port = MIDIPortRef()
    private var destinations: [(name: String, ref: MIDIEndpointRef)] = []
    private(set) var selectedIndex: Int = 0
    var enabled = false

    init() {
        let status = MIDIClientCreateWithBlock("KeySax" as CFString, &client) { [weak self] _ in
            self?.refresh()
        }
        if status == noErr {
            MIDIOutputPortCreate(client, "KeySax Out" as CFString, &port)
        }
        refresh()
    }

    deinit {
        if port != 0 { MIDIPortDispose(port) }
        if client != 0 { MIDIClientDispose(client) }
    }

    var destinationNames: [String] {
        destinations.map(\.name)
    }

    func refresh() {
        destinations.removeAll()
        let count = MIDIGetNumberOfDestinations()
        for i in 0..<count {
            let dest = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(dest, kMIDIPropertyDisplayName, &name)
            let label = name?.takeRetainedValue() as String? ?? "MIDI \(i + 1)"
            destinations.append((label, dest))
        }
        if selectedIndex >= destinations.count { selectedIndex = 0 }
    }

    func select(index: Int) {
        guard destinations.indices.contains(index) else { return }
        selectedIndex = index
    }

    func noteOn(midi: Int, velocity: UInt8) {
        send(status: 0x90, note: UInt8(max(0, min(127, midi))), value: velocity)
    }

    func noteOff(midi: Int) {
        send(status: 0x80, note: UInt8(max(0, min(127, midi))), value: 0)
    }

    func allOff() {
        send(status: 0xB0, note: 123, value: 0)
    }

    private func send(status: UInt8, note: UInt8, value: UInt8) {
        guard enabled, port != 0, destinations.indices.contains(selectedIndex) else { return }
        var packetList = MIDIPacketList()
        let dest = destinations[selectedIndex].ref
        withUnsafeMutablePointer(to: &packetList) { listPtr in
            var pkt = MIDIPacketListInit(listPtr)
            var data: [UInt8] = [status, note, value]
            pkt = MIDIPacketListAdd(
                listPtr,
                MemoryLayout<MIDIPacketList>.size,
                pkt,
                0,
                3,
                &data
            )
            _ = pkt
            MIDISend(port, dest, listPtr)
        }
    }
}
