#Include <Actions>
#Include <Utils>
#Include <Functions>
#Include <NotifyClass-NotifyCreator\Notify>

; $Win
*#e:: ActivateOrRun("此电脑 ahk_class CabinetWClass", "explorer.exe")
*#t:: ActivateOrRun("", "shortcuts\Notepad3.lnk")
*#m:: ToggleWindowTopMost()
*#q:: SmartCloseWindow()
*#s:: MaximizeWindow()

; $Alt + Shift
;*+!b::ActivateOrRun("ahk_exe msedge.exe", "shortcuts\Microsoft Edge Dev.lnk")
;*+!c::ActivateOrRun("ahk_exe cloudmusic.exe", "shortcuts\网易云音乐.lnk", "", "", false, true, false)
;*+!d::ActivateOrRun("ahk_exe Telegram.exe", "shortcuts\Telegram.lnk")
;*+!e::ActivateOrRun("Download (F:) ahk_class CabinetWClass ahk_exe explorer.exe", "explorer.exe", "F:", "", false, false, false)
;*+!t::ActivateOrRun("", "shortcuts\Notepad3.lnk")

;*+!v::RunProgramsExplorer("code", ".", "") ; VsCode
;*+!g::RunProgramsExplorer("goland", ".", "") ; GoLand

; terminal
*#!enter:: {
    ;ProcessName := WinGetProcessName("A")
    ;if (ProcessName == "Code.exe") {
    ;    Send("^{F10}")
    ;}else if (ProcessName == "goland64.exe"){
    ;    Send("!{F12}")
    ;}else{
    ;    RunProgramsExplorer("wt", "", "F:")
    ;}
    RunProgramsExplorer("wt", "-p Arch", "\\wsl.localhost\Arch\home\q")
}

;https://learn.microsoft.com/zh-cn/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7?view=powershell-7.5
*#enter:: {
    ; MoveOrGotoDesktopNumber(5)
    RunProgramsExplorer("wt", "", "F:")
    ;ActivateOrRun("ahk_class CASCADIA_HOSTING_WINDOW_CLASS", "wt", "-M -d F:")
}

;#HotIf WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")
;*#enter::Send("+!=")
;*#^enter::Send("+!-")

;*#q::Send("^+w")

;*#Up::Send("!{Up}")
;*#Down::Send("!{Down}")
;*#Left::Send("!{Left}")
;*#Right::Send("!{Right}")
;#HotIf

ChangeAudioOutput(device, show_msg_box := true) {
    symbols := Map("Headphones", "🎧耳机", "Speakers", "🔊扬声器", "Display", "🖥显示器️")
    if (show_msg_box)
        Notify.Show(symbols[device], , , , , 'dur=1 pos=BC ts=12')
    Run("nircmd.exe setdefaultsounddevice " device)  ; change device using nircmd
}

ChangeAudioOutput("Speakers", false)

#a:: {
    static device := "Speakers"  ; use a static variable

    if (device = "Headphones") {
        device := "Speakers"
    }
    else if (device = "Speakers") {
        device := "Headphones"
    }

    ; if the audio output device is anything else than headphones/speakers, set it to Headphones
    else if not (device := "Headphones" or device := "Speakers") {
        device := "Headphones"
    }

    ; change device using nircmd
    ChangeAudioOutput(device, true)
}

#!v:: { ; 快捷键：Win + Alt + V (解义粘贴)
    PasteProcessed(StrReplace(StrReplace(A_Clipboard, "\n", "`n"), "\t", "`t"))
}

#^v:: { ; 快捷键：Win + Ctrl + V (转义粘贴)
    t := StrReplace(StrReplace(A_Clipboard, "`r`n", "\n"), "`n", "\n")
    PasteProcessed(StrReplace(t, "`t", "\t"))
}

#+v:: { ; 快捷键：Win + Shift + V (转义粘贴带号)
    t := StrReplace(A_Clipboard, "\", "\\")
    t := StrReplace(StrReplace(t, "`r`n", "\n"), "`n", "\n")
    t := StrReplace(t, "`t", "\t")
    PasteProcessed(StrReplace(t, '"', '\"'))
}

PasteProcessed(content) {
    original := A_Clipboard
    A_Clipboard := content
    if ClipWait(0.5) {
        Send "^v"
        Sleep 100
    }
    A_Clipboard := original
}

#n:: {
    Run "C:\Users\micro\AppData\Local\Programs\Zed\Zed.exe"
}


; 抑制Win键弹出开始菜单
~LWin:: Send "{Blind}{vkE8}"

; Win+Shift+S 热键 用于移动窗口到下一个显示器
#+s:: {
    try {
        ; 获取活动窗口
        activeHwnd := WinExist("A")
        if !activeHwnd {
            MsgBox "没有找到活动窗口"
            return
        }

        ; 获取窗口当前位置
        WinGetPos &X, &Y, &W, &H, activeHwnd

        ; 获取所有显示器信息
        monitors := MonitorGetCount()
        if (monitors < 2) {
            MsgBox "只有一个显示器，无需移动"
            return
        }

        ; 找出窗口当前所在的显示器
        currentMonitor := 0
        loop monitors {
            MonitorGetWorkArea A_Index, &L, &T, &R, &B
            if (X >= L && X < R && Y >= T && Y < B) {
                currentMonitor := A_Index
                break
            }
        }

        if !currentMonitor {
            currentMonitor := 1  ; 如果没找到，默认在第一个显示器
        }

        ; 计算下一个显示器
        nextMonitor := currentMonitor + 1
        if (nextMonitor > monitors) {
            nextMonitor := 1
        }

        ; 获取下一个显示器的工作区
        MonitorGetWorkArea nextMonitor, &nextL, &nextT, &nextR, &nextB

        ; 计算窗口在新显示器中的位置（居中显示）
        newX := nextL + (nextR - nextL - W) // 2
        newY := nextT + (nextB - nextT - H) // 3  ; 除以3让窗口稍微靠上

        ; 移动窗口
        WinMove newX, newY, W, H, activeHwnd

        ; 可选：激活窗口以确保它保持焦点
        WinActivate activeHwnd
    }
    catch as e {
        MsgBox "移动窗口时出错: " e.Message
    }
}
