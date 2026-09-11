# KeyboardFixer for Windows

KeyboardFixer แก้ข้อความที่พิมพ์ด้วยภาษาแป้นพิมพ์ผิด โดยจับคู่จากปุ่มจริงและสถานะ Shift ระหว่าง English US กับ Thai Kedmanee ไม่ใช่การแปลภาษา และไม่ใช้อินเทอร์เน็ต

ตัวอย่าง:

```text
z,vpkdlihk'cvr
ผมอยากสร้างแอพ
```

## ความต้องการของระบบ

- Windows 10 หรือ Windows 11
- Windows PowerShell 5.1 ซึ่งมีมากับ Windows
- ไม่ต้องติดตั้ง .NET หรือโปรแกรมเสริม

## วิธีติดตั้งแบบแนะนำ

1. ดาวน์โหลด `KeyboardFixer-Windows-v2.1.0-Setup.exe` จาก GitHub Releases
2. ดับเบิลคลิกไฟล์ แล้วกด Install
3. หาก Windows แสดงคำเตือน ให้ตรวจสอบว่าดาวน์โหลดไฟล์จากหน้า Release ที่ถูกต้องก่อนอนุญาตให้เรียกใช้
4. มองหา KeyboardFixer ใน notification area บริเวณใกล้นาฬิกา อาจต้องกดลูกศร `^` เพื่อดูไอคอนที่ซ่อนอยู่

โปรแกรมติดตั้งเฉพาะบัญชีผู้ใช้ปัจจุบันไว้ที่ `%LOCALAPPDATA%\KeyboardFixer` จึงไม่ต้องใช้สิทธิ์ Administrator และตั้งให้เปิดเองเมื่อเข้าสู่ Windows

ไฟล์ `Install KeyboardFixer.bat` มีไว้เป็นวิธีสำรองสำหรับชุด source/portable เท่านั้น ผู้ใช้ทั่วไปควรใช้ไฟล์ Setup.exe

## วิธีใช้แบบเร็ว

- แก้ Clipboard: คัดลอกข้อความ แล้วกด `Ctrl+Shift+V` จากนั้นวางตามปกติด้วย `Ctrl+V`
- แก้ข้อความตรงจุด: ลากเลือกข้อความในช่องที่แก้ไขได้ แล้วกด `Ctrl+Shift+X`
- เปิดหน้าต่าง: ดับเบิลคลิกไอคอน KeyboardFixer ใกล้นาฬิกา

ในโหมด Auto โปรแกรมจะไม่แก้ URL, อีเมล, โค้ด หรือข้อความที่เดาทิศทางไม่ได้ หากต้องการบังคับ ให้เปิดหน้าต่างแล้วเลือก `English to Thai` หรือ `Thai to English`

## ปุ่มลัดใช้ไม่ได้

1. ปิดโปรแกรมอื่นที่ใช้ปุ่มลัดเดียวกัน
2. คลิกขวาไอคอน KeyboardFixer แล้วเลือก Exit จากนั้นเปิดใหม่จาก Start menu
3. การแทนข้อความที่เลือกทำงานเฉพาะบริเวณที่อนุญาตให้คัดลอกและวางข้อความ
4. แอปบางตัวที่รันด้วยสิทธิ์ Administrator จะไม่รับการกดปุ่มจำลองจากแอปสิทธิ์ปกติ ให้ใช้วิธีแก้ Clipboard แทน

Windows ไม่ต้องใช้ Accessibility permission แบบ macOS เพราะรุ่นนี้ใช้ Clipboard และ Windows hotkey API

## ถอนการติดตั้ง

1. คลิกขวาไอคอน KeyboardFixer ใกล้นาฬิกา แล้วเลือก Exit
2. เปิด Windows Settings → Apps → Installed apps
3. ค้นหา KeyboardFixer แล้วเลือก Uninstall

## ความเป็นส่วนตัว

KeyboardFixer ทำงานแบบออฟไลน์ทั้งหมด ไม่มี analytics, telemetry หรือ network request โปรแกรมอ่าน Clipboard เมื่อผู้ใช้กดปุ่มในหน้าต่างหรือใช้ปุ่มลัดเท่านั้น และไม่เก็บประวัติ Clipboard

## สำหรับนักพัฒนา

`KeyboardFixer.Core.ps1` เก็บตารางแป้นพิมพ์และตรรกะแปลงข้อความ ส่วน `KeyboardFixer.ps1` ดูแลหน้าต่าง system tray, Clipboard และ global hotkeys ตารางภาษาไทยเขียนด้วย Unicode scalar code points เพื่อให้ทำงานถูกต้องบน Windows PowerShell 5.1 โดยไม่ขึ้นกับ encoding ของไฟล์

เปิด PowerShell ในโฟลเดอร์นี้แล้วรันชุดทดสอบด้วย:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-KeyboardFixer.ps1
```

อักขระปลายทางซ้ำจะถูกเก็บเป็นรายการผู้สมัครทั้งหมด และการแปลงย้อนกลับจะเลือกปุ่มแรกตามลำดับแป้นพิมพ์อย่างแน่นอน จึงไม่เกิด dictionary collision หรือ crash
