#Include <Actions>
#Include <Utils>
#Include <Functions>
#Include <NotifyClass-NotifyCreator\Notify>

; $Win
*#t:: ActivateOrRun("", "zed")
*#m:: ToggleWindowTopMost()
*#q:: SmartCloseWindow()
*#s:: MaximizeWindow()

; terminal, 快捷打开终端, 支持资源管理器智能设置工作目录
; alt表示wsl, ctrl表示管理员模式
*#!enter:: {
    RunProgramsExplorer("wt.exe", "-p Arch", "\\wsl.localhost\Arch\home\q", GetKeyState("Ctrl", "P"))
}
*#enter:: {
    ; https://learn.microsoft.com/zh-cn/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7?view=powershell-7.5
    RunProgramsExplorer("wt.exe", "", "F:", GetKeyState("Ctrl", "P"))
    ;ActivateOrRun("ahk_class CASCADIA_HOSTING_WINDOW_CLASS", "wt", "-M -d F:")
}

; Win + A：实时轮询所有当前可用的音频输出设备
#a:: {
    ; MMDeviceEnumerator
    enumerator := ComObject(
        "{BCDE0395-E52F-467C-8E3D-C4579291692E}",
        "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
    )

    ; 获取当前默认输出设备
    currentDevice := 0
    ComCall(
        4,
        enumerator,
        "UInt", 0, ; eRender
        "UInt", 1, ; eMultimedia
        "Ptr*", &currentDevice
    )

    currentId := ""
    if currentDevice {
        idPtr := 0
        ComCall(5, currentDevice, "Ptr*", &idPtr)
        currentId := StrGet(idPtr)
        DllCall("Ole32\CoTaskMemFree", "Ptr", idPtr)
    }

    ; 实时枚举 ACTIVE 的播放设备
    collection := 0
    ComCall(
        3,
        enumerator,
        "UInt", 0, ; eRender
        "UInt", 1, ; DEVICE_STATE_ACTIVE
        "Ptr*", &collection
    )

    count := 0
    ComCall(3, collection, "UInt*", &count)

    devices := []

    loop count {
        device := 0
        ComCall(
            4,
            collection,
            "UInt", A_Index - 1,
            "Ptr*", &device
        )

        ; Device ID
        idPtr := 0
        ComCall(5, device, "Ptr*", &idPtr)
        deviceId := StrGet(idPtr)
        DllCall("Ole32\CoTaskMemFree", "Ptr", idPtr)

        ; Friendly Name
        store := 0
        ComCall(
            4,
            device,
            "UInt", 0, ; STGM_READ
            "Ptr*", &store
        )

        ; PKEY_Device_FriendlyName
        propertyKey := Buffer(20, 0)

        NumPut("UInt", 0xA45C254E, propertyKey, 0)
        NumPut("UShort", 0xDF1C, propertyKey, 4)
        NumPut("UShort", 0x4EFD, propertyKey, 6)
        NumPut("UChar", 0x80, propertyKey, 8)
        NumPut("UChar", 0x20, propertyKey, 9)
        NumPut("UChar", 0x67, propertyKey, 10)
        NumPut("UChar", 0xD1, propertyKey, 11)
        NumPut("UChar", 0x46, propertyKey, 12)
        NumPut("UChar", 0xA8, propertyKey, 13)
        NumPut("UChar", 0x50, propertyKey, 14)
        NumPut("UChar", 0xE0, propertyKey, 15)
        NumPut("UInt", 14, propertyKey, 16)

        propVariant := Buffer(A_PtrSize = 8 ? 24 : 16, 0)

        ComCall(
            5,
            store,
            "Ptr", propertyKey,
            "Ptr", propVariant
        )

        namePtr := NumGet(propVariant, 8, "Ptr")
        name := namePtr ? StrGet(namePtr) : deviceId

        DllCall(
            "Ole32\PropVariantClear",
            "Ptr", propVariant
        )

        devices.Push({
            id: deviceId,
            name: name
        })
    }

    if devices.Length < 2 {
        Notify.Show(
            "没有可切换的音频输出设备",
            ,
            ,
            ,
            ,
            "dur=1 pos=BC ts=12"
        )
        return
    }

    ; 找到当前设备
    currentIndex := 0

    for i, device in devices {
        if device.id = currentId {
            currentIndex := i
            break
        }
    }

    ; 当前设备 → 下一个设备
    nextIndex := currentIndex
        ? Mod(currentIndex, devices.Length) + 1
        : 1

    nextDevice := devices[nextIndex]

    ; IPolicyConfig
    policyConfig := ComObject(
        "{870AF99C-171D-4F9E-AF0D-E63DF40C2BC9}",
        "{F8679F50-850A-41CF-9C72-430F290290C8}"
    )

    ; eConsole
    ComCall(
        13,
        policyConfig,
        "Str", nextDevice.id,
        "Int", 0
    )

    ; eMultimedia
    ComCall(
        13,
        policyConfig,
        "Str", nextDevice.id,
        "Int", 1
    )

    Notify.Show(
        nextDevice.name,
        ,
        ,
        ,
        ,
        "dur=1 pos=BC ts=12"
    )
}

#!v:: { ; 快捷键：Win + Alt + V (解义粘贴)
    PasteProcessed(StrReplace(StrReplace(A_Clipboard, "\n", "`n"), "\t", "`t"))
}

#^!v:: { ; 快捷键：Win + +Ctrl + Alt + V (解义粘贴)
    PasteProcessed(StrReplace(StrReplace(StrReplace(A_Clipboard, "\n", "`n"), "\t", "`t"),'\"','"'))
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
