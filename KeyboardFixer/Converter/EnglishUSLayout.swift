import Foundation

struct EnglishUSLayout: KeyboardLayout {
    let name = "English (US)"

    let keyMap = KeyboardLayoutBuilder.makeMap(
        unshifted: "`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./",
        shifted: "~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?"
    )
}
