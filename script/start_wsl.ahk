#Requires AutoHotkey v2.0
#SingleInstance Force

global WSL_ID := 0
global INIT_TITLE := "WSL_GHOST_RUNNER_" . A_TickCount
global CMD_RUN := 'wt.exe -w new -d ~ --title "' . INIT_TITLE . '" wsl.exe'

Hotkey "^!w", ToggleWsl

SetWinEventHook(0x0003, 0x0003, 0, CallbackCreate(OnForegroundChange, "F"), 0, 0, 0)
OnExit(ExitFunc)

ToggleWsl()

ToggleWsl(*) {
    global WSL_ID

    if !WinExist(WSL_ID) {
        Run(CMD_RUN)
        if WinWait(INIT_TITLE, , 3) {
            WSL_ID := WinExist(INIT_TITLE)
            WinSetStyle("-0x80000", WSL_ID)
            WinActivate(WSL_ID)
        }
    } else {
        if WinGetStyle(WSL_ID) & 0x10000000 {
            WinHide(WSL_ID)
        } else {
            WinShow(WSL_ID)
            WinActivate(WSL_ID)
        }
    }
}

OnForegroundChange(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
    global WSL_ID
    if (WSL_ID && WinExist(WSL_ID)) {
        if (WinGetStyle(WSL_ID) & 0x10000000) {
            if (hwnd != WSL_ID) {
                WinHide(WSL_ID)
            }
        }
    }
}

ExitFunc(*) {
    global WSL_ID
    if WinExist(WSL_ID)
        WinClose(WSL_ID)
}

SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags) {
    DllCall("user32\SetWinEventHook", "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc, "Ptr",
        lpfnWinEventProc, "UInt", idProcess, "UInt", idThread, "UInt", dwFlags)
}
