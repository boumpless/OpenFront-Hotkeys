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
trainKey := IniRead(configFile, "Hotkeys", "train", "l")
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
calibrateMousePositionKey := IniRead(configFile, "Hotkeys", "calibrateMousePosition", "m")
increaseDelayKey := IniRead(configFile, "Hotkeys", "increaseDelay", "o")
decreaseDelayKey := IniRead(configFile, "Hotkeys", "decreaseDelay", "p")

; Settings
baseDelay := IniRead(configFile, "Settings", "baseDelay", "100")
buttonSizeX := IniRead(configFile, "Settings", "buttonSizeX", "140")
buttonSizeY := IniRead(configFile, "Settings", "buttonSizeY", "150")
maxNbButtonsBuildRow := IniRead(configFile, "Settings", "maxNbButtonsBuildRow", "6")
browserMenuSize := IniRead(configFile, "Settings", "browserMenuSize", "100")

; Liste des boutons possibles
buttonList := ["Atom Bomb", "MIRV", "Hydrogen Bomb", "Warship", "Port", "Missile Silo", "SAM Launcher", "Defense Post", "City", "Train"]

; Créer la GUI pour sélectionner les boutons présents
SelectButtonsGui() {
    global buttonList, selectedButtons
    selectedButtons := []
    MyGui := Gui("+AlwaysOnTop", "Sélection des boutons présents")
    for index, button in buttonList {
        MyGui.Add("Checkbox", "vChk" index, button)
    }
    MyGui.Add("Button", "Default", "OK").OnEvent("Click", (*) => SubmitSelections(MyGui))
    MyGui.Show()
}

SubmitSelections(guiObj) {
    global selectedButtons, buttonList
    for index, button in buttonList
        if guiObj["Chk" index].Value
            selectedButtons.Push(button)
    guiObj.Destroy()
}

; Appeler la GUI au démarrage
SelectButtonsGui()
; Attendre que la GUI soit fermée
while !selectedButtons
    Sleep 100

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

    MsgBox "1. Click on `"OK`"`n2. Ctrl + click anywhere to open Build menu`n3. Remember how many buttons there are on the FIRST row (max 10)`n4. Click on the TOP LEFT corner of Atom Bomb button (1st button)`n5. Click on BOTTOM LEFT corner of Train button (2nd button)",
        "Settings - Buttons calibration", "OK"

    first := WaitForClick()
    second := WaitForClick()
    buttonSizeX := Abs(second.x - first.x)
    buttonSizeY := Abs(second.y - first.y)

    resultNbButtons := InputBox("How many buttons on top row of build menu ? (max 10)", "Settings - Buttons calibration",
        "")
    userNbButtons := resultNbButtons.Value
    if !IsInteger(userNbButtons) || userNbButtons < 0 || userNbButtons > 10 {
        MsgBox("please enter the number of buttons in the top row (1 - 10)", "Error", "Iconx")
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

GetButtonCoords(buttonName) {
    global selectedButtons, maxNbButtonsBuildRow, buttonSizeX, buttonSizeY, browserMenuSize

    ; Trouver la position du bouton dans la liste sélectionnée
    buildPosition := 0
    for index, button in selectedButtons {
        if button = buttonName {
            buildPosition := index
            break
        }
    }
    if buildPosition = 0 {
        MsgBox("Bouton non trouvé : " buttonName)
        return [0, 0]
    }

    row := (buildPosition - 1) // maxNbButtonsBuildRow
    pos := Mod((buildPosition - 1), maxNbButtonsBuildRow)

    fullRows := selectedButtons.Length // maxNbButtonsBuildRow
    remaining := Mod(selectedButtons.Length, maxNbButtonsBuildRow)
    isLastRow := (row = fullRows) && (remaining != 0)
    elementsInRow := isLastRow ? remaining : maxNbButtonsBuildRow

    centerOffset := (elementsInRow - 1) / 2

    totalRows := Ceil(selectedButtons.Length / maxNbButtonsBuildRow)
    rowCenterOffset := (totalRows - 1) / 2

    WinGetPos(&x, &y, &w, &h, "A")  ; "A" = active window
    centerX := w // 2
    centerY := h // 2 + browserMenuSize / 2

    buttonX := (pos - centerOffset) * buttonSizeX + centerX
    buttonY := (row - rowCenterOffset) * buttonSizeY + centerY

    return [buttonX, buttonY]
}

Build(buttonName) {
    global baseDelay
    buttonCoords := GetButtonCoords(buttonName)
    buttonX := buttonCoords[1]
    buttonY := buttonCoords[2]
    if buttonX = 0 && buttonY = 0
        return
    BlockInput true
    MouseGetPos &x0, &y0

    Send('{Ctrl down}')
    Click 'left'
    Send('{Ctrl up}')

    MouseMove buttonX, buttonY, 0
    Sleep baseDelay

    Click 'left'

    MouseMove x0, y0, 0
    BlockInput false
}

BuildCity() {
    Build("City")
}

BuildDefensePost() {
    Build("Defense Post")
}

BuildPort() {
    Build("Port")
}

BuildMissileSilo() {
    Build("Missile Silo")
}

BuildSAMLauncher() {
    Build("SAM Launcher")
}

BuildWarship() {
    Build("Warship")
}

BuildTrain() {
    Build("Train")
}

SendAtomBomb() {
    Build("Atom Bomb")
}

SendHydrogenBomb() {
    Build("Hydrogen Bomb")
}

SendMIRV() {
    Build("MIRV")
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
Hotkey(trainKey, (*) => BuildTrain())
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
