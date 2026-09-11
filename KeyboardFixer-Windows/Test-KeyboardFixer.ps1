Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'KeyboardFixer.Core.ps1')

function Assert-Equal {
    param([string]$Expected, [string]$Actual, [string]$Name)
    if ($Expected -cne $Actual) {
        throw "$Name failed. Expected '$Expected', got '$Actual'."
    }
}

$thaiSample = ConvertFrom-KeyboardFixerHexScalars '0E1C 0E21 0E2D 0E22 0E32 0E01 0E2A 0E23 0E49 0E32 0E07 0E41 0E2D 0E1E'
Assert-Equal $thaiSample (Convert-KeyboardFixerText "z,vpkdlihk'cvr" EnglishToThai) 'English sample'
Assert-Equal "z,vpkdlihk'cvr" (Convert-KeyboardFixerText $thaiSample ThaiToEnglish) 'Thai sample'
Assert-Equal (ConvertFrom-KeyboardFixerHexScalars '0E1F') (Convert-KeyboardFixerText 'a' EnglishToThai) 'a'
Assert-Equal (ConvertFrom-KeyboardFixerHexScalars '0E24') (Convert-KeyboardFixerText 'A' EnglishToThai) 'A'
Assert-Equal (ConvertFrom-KeyboardFixerHexScalars '0E1C') (Convert-KeyboardFixerText 'z' EnglishToThai) 'z'
Assert-Equal '(' (Convert-KeyboardFixerText 'Z' EnglishToThai) 'Z'
Assert-Equal (ConvertFrom-KeyboardFixerHexScalars '0E45') (Convert-KeyboardFixerText '1' EnglishToThai) '1'
Assert-Equal '+' (Convert-KeyboardFixerText '!' EnglishToThai) '!'
$emoji = [char]::ConvertFromUtf32(0x1F642)
Assert-Equal "`r`n`t$emoji" (Convert-KeyboardFixerText "`r`n`t$emoji" EnglishToThai) 'Whitespace and emoji'
Assert-Equal 'Uncertain' (Get-KeyboardFixerDetection 'https://example.com') 'URL detection'

$layouts = Get-KeyboardFixerLayouts
foreach ($physicalKey in $layouts.PhysicalKeys) {
    foreach ($shifted in 0, 1) {
        $key = "$physicalKey|$shifted"
        $englishCharacter = $layouts.English[$key]
        $thaiCharacter = $layouts.Thai[$key]
        Assert-Equal $englishCharacter (Convert-KeyboardFixerText (Convert-KeyboardFixerText $englishCharacter EnglishToThai) ThaiToEnglish) "English round trip $key"
        if ($layouts.ThaiReverse[$thaiCharacter].Count -eq 1) {
            Assert-Equal $thaiCharacter (Convert-KeyboardFixerText (Convert-KeyboardFixerText $thaiCharacter ThaiToEnglish) EnglishToThai) "Thai round trip $key"
        }
    }
}

Write-Host 'PASS: KeyboardFixer Windows core tests' -ForegroundColor Green
