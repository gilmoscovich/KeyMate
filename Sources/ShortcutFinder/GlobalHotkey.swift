import Carbon
import Foundation

/// Uses RegisterEventHotKey: no global key logging or Accessibility permission.
@MainActor
final class GlobalHotkey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var action: (() -> Void)?
    func register(action: @escaping () -> Void) -> OSStatus {
        unregister()
        self.action = action
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let install = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let owner = Unmanaged<GlobalHotkey>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { owner.action?() }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard install == noErr else { return install }
        let identifier = EventHotKeyID(signature: 0x53434644, id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_K), UInt32(controlKey | optionKey), identifier, GetApplicationEventTarget(), 0, &reference)
        if status != noErr { unregister() }
        return status
    }
    func unregister() {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
        reference = nil; handler = nil; action = nil
    }
}
