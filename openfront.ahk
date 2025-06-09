; To edit settings and hotkeys other than Exit Pause/Unpause, edit openfront-config.ini
#Requires AutoHotkey v2.0
#SingleInstance

#SuspendExempt
; Check List of Keys : https://www.autohotkey.com/docs/v2/KeyList.htm
; And prefixes for combinaison hotkeys : https://www.autohotkey.com/docs/v2/KeyList.htm#modifier
Esc:: ExitApp() ;    <-- Edit this hotkey to Exit the script
!p:: Suspend(-1) ;  <-- Edit this hotkey to Pause/Unpause the script
#SuspendExempt False

; Mouse coords in the current window without borders nor title bar
CoordMode("Mouse", "Client")

SendMode "Input"

; Look for openfront-config.ini in same dir .ahk script
SetWorkingDir(A_ScriptDir)
configFile := "openfront-config.ini"

; Hotkeys - EDIT HOTKEYS IN openfront-config.ini !!
; Build keys
cityKey := IniRead(configFile, "Hotkeys", "city", "f")
portKey := IniRead(configFile, "Hotkeys", "port", "g")
defensePostKey := IniRead(configFile, "Hotkeys", "defensePost", "h")
missileSiloKey := IniRead(configFile, "Hotkeys", "missileSilo", "j")
sAMLauncherKey := IniRead(configFile, "Hotkeys", "sAMLauncher", "k")
; Send keys
warshipKey := IniRead(configFile, "Hotkeys", "warship", "r")
atomBombKey := IniRead(configFile, "Hotkeys", "atomBomb", "t")
hydrogenBombKey := IniRead(configFile, "Hotkeys", "hydrogenBomb", "y")
mIRVKey := IniRead(configFile, "Hotkeys", "mIRV", "u")
; Actions keys
navalInvasionKey := IniRead(configFile, "Hotkeys", "navalInvasion", "x")
allyBetrayKey := IniRead(configFile, "Hotkeys", "allyBetray", "v")
playerInfoKey := IniRead(configFile, "Hotkeys", "playerInfo", "b")
; Settings keys
calibrateMousePositionKey := IniRead(configFile, "Hotkeys", "calibrateMousePositionKey", "l")
increaseDelayKey := IniRead(configFile, "Hotkeys", "increaseDelay", "o")
decreaseDelayKey := IniRead(configFile, "Hotkeys", "decreaseDelay", "p")

; Settings
baseDelay := IniRead(configFile, "Settings", "baseDelay", "100")
buttonSizeX := IniRead(configFile, "Settings", "buttonSizeX", "140")
buttonSizeY := IniRead(configFile, "Settings", "buttonSizeY", "150")
maxNbButtonsBuildRow := IniRead(configFile, "Settings", "maxNbButtonsBuildRow", "6")
browserMenuSize := IniRead(configFile, "Settings", "browserMenuSize", "100")

totalNbBuildButtons := 9
buttonSize := 170

IncreaseDelay() {
    global baseDelay
    baseDelay += 10
    SaveAndNotifyDelay(baseDelay)
}

DecreaseDelay() {
    global baseDelay
    baseDelay -= 10
    if baseDelay < 0
        baseDelay := 0
    SaveAndNotifyDelay(baseDelay)
}

SaveAndNotifyDelay(val) {
    IniWrite(val, "openfront-config.ini", "Settings", "baseDelay")

    MyGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
    MyGui.Add("Text", "Center vCenter", "baseDelay : " val "")
    MyGui.Show("xCenter yCenter NoActivate AutoSize")
    SetTimer(() => MyGui.Destroy(), 500)
}

CalibrateMousePosition() {
    global buttonSizeX
    global buttonSizeY
    global maxNbButtonsBuildRow
    global browserMenuSize

    MsgBox "1. Click on `"OK`"`n2. Click on the high end of your browser window`n3. Click on the boundary between your browser menu and openfront content",
        "Settings - Offset calibration", "OK"

    first := WaitForClick()
    second := WaitForClick()
    browserMenuSize := Abs(second.y - first.y)

    MsgBox "1. Click on `"OK`"`n2. Ctrl + click anywhere to open Build menu`n3. Remember how many buttons there are on the FIRST row (max 9)`n4. Click on the TOP LEFT corner of Atom Bomb button (1st button)`n5. Click on BOTTOM LEFT corner of MIRV button (2nd button)",
        "Settings - Buttons calibration", "OK"

    first := WaitForClick()
    second := WaitForClick()
    buttonSizeX := Abs(second.x - first.x)
    buttonSizeY := Abs(second.y - first.y)

    resultNbButtons := InputBox("How many buttons on top row of build menu ? (max 9)", "Settings - Buttons calibration",
        "")
    userNbButtons := resultNbButtons.Value
    if !IsInteger(userNbButtons) || userNbButtons < 0 || userNbButtons > 9 {
        MsgBox("please enter the numbers of buttosn in the top row (1 - 9)", "Error", "Iconx")
        return
    }
    maxNbButtonsBuildRow := userNbButtons

    IniWrite buttonSizeX, "openfront-config.ini", "Settings", "buttonSizeX"
    IniWrite buttonSizeY, "openfront-config.ini", "Settings", "buttonSizeY"
    IniWrite maxNbButtonsBuildRow, "openfront-config.ini", "Settings", "maxNbButtonsBuildRow"
    IniWrite browserMenuSize, "openfront-config.ini", "Settings", "browserMenuSize"

    myGui := Gui("+AlwaysOnTop +ToolWindow -Caption")
    myGui.Add("Text", "Center vCenter", "Settings saved in openfront-config.ini")
    myGui.Show("xCenter yCenter NoActivate AutoSize")
    SetTimer(() => myGui.Destroy(), 2000)

}

WaitForClick() {
    loop {
        Sleep 10
        if GetKeyState("LButton", "P") && !GetKeyState("Ctrl", "P") {
            while GetKeyState("LButton", "P")
                Sleep 10
            MouseGetPos &x, &y
            return { x: x, y: y }
        }
    }
}

GetButtonCoords(buildPosition) {
    global maxNbButtonsBuildRow
    global buttonSizeX
    global buttonSizeY
    global browserMenuSize

    row := (buildPosition - 1) // maxNbButtonsBuildRow
    pos := Mod((buildPosition - 1), maxNbButtonsBuildRow)

    fullRows := totalNbBuildButtons // maxNbButtonsBuildRow
    remaining := Mod(totalNbBuildButtons, maxNbButtonsBuildRow)
    isLastRow := (row = fullRows) && (remaining != 0)
    elementsInRow := isLastRow ? remaining : maxNbButtonsBuildRow

    centerOffset := (elementsInRow - 1) / 2

    totalRows := Ceil(totalNbBuildButtons / maxNbButtonsBuildRow)
    rowCenterOffset := (totalRows - 1) / 2

    WinGetPos(&x, &y, &w, &h, "A")  ; "A" = active window
    centerX := w // 2
    centerY := h // 2 + browserMenuSize / 2

    buttonX := (pos - centerOffset) * buttonSizeX + centerX
    buttonY := (row - rowCenterOffset) * buttonSizeY + centerY

    return [buttonX, buttonY]
}

Build(x, y) {
    global baseDelay
    BlockInput true
    MouseGetPos &x0, &y0

    Send('{Ctrl down}')
    Click 'left'
    Send('{Ctrl up}')

    MouseMove x, y, 0
    Sleep baseDelay

    Click 'left'

    MouseMove x0, y0, 0
    BlockInput true
}

BuildCity() {
    buildPosition := 9
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

BuildDefensePost() {
    buildPosition := 8
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}
BuildPort() {
    buildPosition := 5
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

BuildMissileSilo() {
    buildPosition := 6
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

BuildSAMLauncher() {
    buildPosition := 7
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

BuildWarship() {
    buildPosition := 4
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

SendAtomBomb() {
    buildPosition := 1
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

SendHydrogenBomb() {
    buildPosition := 3
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

SendMIRV() {
    buildPosition := 2
    buttonCoords := GetButtonCoords(buildPosition)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    Build(buttonX, buttonY)
}

; --- ACTIONS ---
ActionMenu(x, y) {
    global baseDelay
    BlockInput true
    MouseGetPos &x0, &y0

    Click 'right'

    MouseMove x, y, , "R"

    Sleep(baseDelay * 2)
    Click 'left'

    MouseMove x0, y0
    BlockInput False
}

SendNavalInvasion() {
    ActionMenu(60, 0)
}

AllyBetray() {
    ActionMenu(0, 60)
}

PlayerInfo() {
    ActionMenu(0, -60)
}

; Map keys to functions
Hotkey(cityKey, (*) => BuildCity())
Hotkey(portKey, (*) => BuildPort())
Hotkey(defensePostKey, (*) => BuildDefensePost())
Hotkey(missileSiloKey, (*) => BuildMissileSilo())
Hotkey(sAMLauncherKey, (*) => BuildSAMLauncher())
Hotkey(warshipKey, (*) => BuildWarship())
Hotkey(atomBombKey, (*) => SendAtomBomb())
Hotkey(hydrogenBombKey, (*) => SendHydrogenBomb())
Hotkey(mIRVKey, (*) => SendMIRV())
Hotkey(navalInvasionKey, (*) => SendNavalInvasion())
Hotkey(allyBetrayKey, (*) => AllyBetray())
Hotkey(playerInfoKey, (*) => PlayerInfo())
Hotkey(calibrateMousePositionKey, (*) => CalibrateMousePosition())
Hotkey(increaseDelayKey, (*) => IncreaseDelay())
Hotkey(decreaseDelayKey, (*) => DecreaseDelay())