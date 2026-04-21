#Requires AutoHotkey v2.0
#SingleInstance Force

; 开机自启 WSL, 并且支持 Ctrl+Alt+w 来切换WSL显示
; 保持后台持续运行 避免自动关机, 跟tun冲突, 而导致 https://github.com/microsoft/WSL/issues/12351

global WSL_ID := 0
global INIT_TITLE := "WSL_GHOST_RUNNER_" . A_TickCount
global CMD_RUN := 'wt.exe -w new -d ~ --title "' . INIT_TITLE . '" wsl.exe'

Hotkey "^!w", ToggleWsl

SetWinEventHook(0x0003, 0x0003, 0, CallbackCreate(OnForegroundChange, "F"), 0, 0, 0)
OnExit(ExitFunc)

ToggleWsl(*) {
    global WSL_ID

    if !WinExist(WSL_ID) {
        Run(CMD_RUN)
        if WinWait(INIT_TITLE,, 3) {
            WSL_ID := WinExist(INIT_TITLE)
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
    DllCall("user32\SetWinEventHook", "UInt", eventMin, "UInt", eventMax, "Ptr", hmodWinEventProc, "Ptr", lpfnWinEventProc, "UInt", idProcess, "UInt", idThread, "UInt", dwFlags)
}

ToggleWsl()
