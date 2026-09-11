Set-StrictMode -Version Latest

$script:PhysicalKeys = @(
    'grave',
    'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'zero',
    'minus', 'equal',
    'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
    'leftBracket', 'rightBracket', 'backslash',
    'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
    'semicolon', 'quote',
    'z', 'x', 'c', 'v', 'b', 'n', 'm',
    'comma', 'period', 'slash'
)

function ConvertFrom-KeyboardFixerHexScalars {
    param([Parameter(Mandatory = $true)][string]$HexScalars)

    $builder = New-Object System.Text.StringBuilder
    foreach ($match in [regex]::Matches($HexScalars, '[0-9A-Fa-f]+')) {
        [void]$builder.Append([char][Convert]::ToInt32($match.Value, 16))
    }
    return $builder.ToString()
}

function New-KeyboardFixerLayout {
    param(
        [Parameter(Mandatory = $true)][string]$Unshifted,
        [Parameter(Mandatory = $true)][string]$Shifted
    )

    $unshiftedCharacters = $Unshifted.ToCharArray()
    $shiftedCharacters = $Shifted.ToCharArray()
    if ($unshiftedCharacters.Count -ne $script:PhysicalKeys.Count -or
        $shiftedCharacters.Count -ne $script:PhysicalKeys.Count) {
        throw 'Keyboard layout must contain one shifted and unshifted character per physical key.'
    }

    $layout = @{}
    for ($index = 0; $index -lt $script:PhysicalKeys.Count; $index++) {
        $layout["$($script:PhysicalKeys[$index])|0"] = [string]$unshiftedCharacters[$index]
        $layout["$($script:PhysicalKeys[$index])|1"] = [string]$shiftedCharacters[$index]
    }
    return $layout
}

function New-KeyboardFixerReverseLayout {
    param([Parameter(Mandatory = $true)][hashtable]$Layout)

    # A normal PowerShell hashtable is case-insensitive. Keyboard conversion
    # must keep Shift state, so "a" and "A" must be separate reverse keys.
    $reverse = New-Object System.Collections.Hashtable([System.StringComparer]::Ordinal)
    foreach ($physicalKey in $script:PhysicalKeys) {
        foreach ($shifted in 0, 1) {
            $key = "$physicalKey|$shifted"
            $character = $Layout[$key]
            if (-not $reverse.ContainsKey($character)) {
                $reverse[$character] = @()
            }
            $reverse[$character] += $key
        }
    }
    return $reverse
}

$englishUnshifted = '`1234567890-=qwertyuiop[]\asdfghjkl;''zxcvbnm,./'
$englishShifted = '~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?'

$thaiUnshifted = ConvertFrom-KeyboardFixerHexScalars @'
005F 0E45 002F 002D 0E20 0E16 0E38 0E36 0E04 0E15 0E08 0E02 0E0A
0E46 0E44 0E33 0E1E 0E30 0E31 0E35 0E23 0E19 0E22 0E1A 0E25 0E03
0E1F 0E2B 0E01 0E14 0E40 0E49 0E48 0E32 0E2A 0E27 0E07
0E1C 0E1B 0E41 0E2D 0E34 0E37 0E17 0E21 0E43 0E1D
'@

$thaiShifted = ConvertFrom-KeyboardFixerHexScalars @'
0025 002B 0E51 0E52 0E53 0E54 0E39 0E3F 0E55 0E56 0E57 0E58 0E59
0E50 0022 0E0E 0E11 0E18 0E4D 0E4A 0E13 0E2F 0E0D 0E10 002C 0E05
0E24 0E06 0E0F 0E42 0E0C 0E47 0E4B 0E29 0E28 0E0B 002E
0028 0029 0E09 0E2E 0E3A 0E4C 003F 0E12 0E2C 0E26
'@

$script:EnglishLayout = New-KeyboardFixerLayout -Unshifted $englishUnshifted -Shifted $englishShifted
$script:ThaiLayout = New-KeyboardFixerLayout -Unshifted $thaiUnshifted -Shifted $thaiShifted
$script:EnglishReverseLayout = New-KeyboardFixerReverseLayout -Layout $script:EnglishLayout
$script:ThaiReverseLayout = New-KeyboardFixerReverseLayout -Layout $script:ThaiLayout

function Convert-KeyboardFixerText {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)]
        [ValidateSet('EnglishToThai', 'ThaiToEnglish')]
        [string]$Direction
    )

    if ($Direction -eq 'EnglishToThai') {
        $sourceReverse = $script:EnglishReverseLayout
        $destination = $script:ThaiLayout
    } else {
        $sourceReverse = $script:ThaiReverseLayout
        $destination = $script:EnglishLayout
    }

    $builder = New-Object System.Text.StringBuilder
    foreach ($character in $Text.ToCharArray()) {
        $value = [string]$character
        if ($sourceReverse.ContainsKey($value)) {
            $physicalKey = $sourceReverse[$value][0]
            [void]$builder.Append($destination[$physicalKey])
        } else {
            [void]$builder.Append($character)
        }
    }
    return $builder.ToString()
}

function Get-KeyboardFixerDetection {
    param([AllowEmptyString()][string]$Text)

    $lowercaseText = $Text.ToLowerInvariant()
    if ($lowercaseText.Contains('://') -or $lowercaseText.StartsWith('www.') -or
        $Text -match '\S+@\S+' -or $Text -match '</|=>|[{}]|\b(func|let|var)\s') {
        return 'Uncertain'
    }

    $latinLetters = 0
    $thaiScalars = 0
    foreach ($character in $Text.ToCharArray()) {
        $codePoint = [int]$character
        if (($codePoint -ge 0x41 -and $codePoint -le 0x5A) -or
            ($codePoint -ge 0x61 -and $codePoint -le 0x7A)) {
            $latinLetters++
        } elseif ($codePoint -ge 0x0E00 -and $codePoint -le 0x0E7F) {
            $thaiScalars++
        }
    }

    $meaningfulCount = $latinLetters + $thaiScalars
    if ($meaningfulCount -lt 2 -or ($latinLetters -gt 0 -and $thaiScalars -gt 0)) {
        return 'Uncertain'
    }
    if ($latinLetters -ge 2 -and ($latinLetters / $meaningfulCount) -ge 0.75) {
        return 'EnglishToThai'
    }
    if ($thaiScalars -ge 2 -and ($thaiScalars / $meaningfulCount) -ge 0.75) {
        return 'ThaiToEnglish'
    }
    return 'Uncertain'
}

function Invoke-KeyboardFixerConversion {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Auto', 'EnglishToThai', 'ThaiToEnglish')]
        [string]$Mode
    )

    $direction = $Mode
    if ($Mode -eq 'Auto') {
        $direction = Get-KeyboardFixerDetection -Text $Text
        if ($direction -eq 'Uncertain') {
            return [pscustomobject]@{ Converted = $false; Text = $Text; Direction = 'Uncertain' }
        }
    }

    return [pscustomobject]@{
        Converted = $true
        Text = Convert-KeyboardFixerText -Text $Text -Direction $direction
        Direction = $direction
    }
}

function Get-KeyboardFixerLayouts {
    return [pscustomobject]@{
        PhysicalKeys = $script:PhysicalKeys
        English = $script:EnglishLayout
        Thai = $script:ThaiLayout
        ThaiReverse = $script:ThaiReverseLayout
    }
}
