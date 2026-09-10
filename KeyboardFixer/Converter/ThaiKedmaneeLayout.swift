import Foundation

struct ThaiKedmaneeLayout: KeyboardLayout {
    let name = "Thai Kedmanee"

    let keyMap = KeyboardLayoutBuilder.makeMap(
        unshifted: "_ๅ/-ภถุึคตจขช" +
            "ๆไำพะัีรนยบลฃ" +
            "ฟหกดเ้่าสวง" +
            "ผปแอิืทมใฝ",
        shifted: "%+๑๒๓๔ู฿๕๖๗๘๙" +
            "๐\"ฎฑธํ๊ณฯญฐ,ฅ" +
            "ฤฆฏโฌ็๋ษศซ." +
            "()ฉฮฺ์?ฒฬฦ"
    )
}
