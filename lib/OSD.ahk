#Requires AutoHotkey v2

global midiSetting

; Position calculator class
class PositionCalculator {
    static GetPosition(position, width, height) {
        workArea := MonitorGetWorkArea(MonitorGetPrimary(), &Left, &Top, &Right, &Bottom)

        positions := Map(
            "topleft", {
                x: Left + appConfig.UI.Margin,
                y: Top + appConfig.UI.Margin
            },
            "topright", {
                x: Right - width - appConfig.UI.Margin,
                y: Top + appConfig.UI.Margin
            },
            "topcenter", {
                x: Left + (Right - Left - width) // 2,
                y: Top + appConfig.UI.Margin
            },
            "bottomleft", {
                x: Left + appConfig.UI.Margin,
                y: Bottom - height - appConfig.UI.Margin
            },
            "bottomright", {
                x: Right - width - appConfig.UI.Margin,
                y: Bottom - height - appConfig.UI.Margin
            },
            "bottomcenter", {
                x: Left + (Right - Left - width) // 2,
                y: Bottom - height - appConfig.UI.Margin
            },
            "centercenter", {
                x: Left + (Right - Left - width) // 2,
                y: Top + (Bottom - Top - height) // 2
            }
        )

        ; Default to bottomright if invalid position specified
        return positions.Has(position) ? positions[position] : positions["bottomright"]
    }
}

; Create the VolumeOSD class
class VolumeOSD {
    static gui := ""
    static position := "topleft"
    static hideTimer := 0
    static controls := Map()

    static Show(name, volume, position := "topcenter") {
        this.position := position
        pos := PositionCalculator.GetPosition(position, appConfig.UI.Volume.Width, appConfig.UI.Volume.Height)

        ; Create GUI if it doesn't exist
        if !this.gui {
            this.InitializeGUI()
        }

        ; Update controls
        this.controls["name"].Value := name
        this.controls["volumeText"].Value := Round(volume) "%"
        this.controls["volumeBar"].Value := Round(volume)

        ; Show/move GUI
        this.gui.Show("x" pos.x " y" pos.y " w" appConfig.UI.Volume.Width " h" appConfig.UI.Volume.Height " NoActivate")

        ; Reset hide timer
        if (this.hideTimer != 0) {
            SetTimer this.hideTimer, 0
        }
        this.hideTimer := ObjBindMethod(this, "Hide")
        SetTimer this.hideTimer, -1500
    }

    static InitializeGUI() {
        this.gui := Gui()
        this.gui.Opt("+AlwaysOnTop -Caption +ToolWindow")
        this.gui.BackColor := "0x1C1C1C"
        WinSetTransparent(230, this.gui)
        WinSetAlwaysOnTop(true, this.gui)

        ; Add controls and store references
        this.gui.SetFont("s20 cWhite", "Segoe UI")
        this.controls["name"] := this.gui.Add("Text", "x10 y10 w280")

        ; Volume bar background (static)
        this.gui.Add("Progress", "x10 y50 w250 h20 Background333333").Value := 100

        ; Volume bar foreground (dynamic)
        this.controls["volumeBar"] := this.gui.Add("Progress", "x10 y50 w250 h20 c0080FF Range0-100")

        ; Volume percentage
        this.gui.SetFont("s11 cWhite", "Segoe UI")
        this.controls["volumeText"] := this.gui.Add("Text", "x265 y50 w40")
    }

    static Hide() {
        if this.gui {
            this.gui.Hide()
        }

        this.hideTimer := 0
    }
}

class Gui2 extends Gui {
    AddImage(image, file, options, text := "") {
        static WS_CHILD := 0x40000000   ; Creates a child window.
        static WS_VISIBLE := 0x10000000   ; Show on creation.
        static WS_DISABLED := 0x8000000   ; Disables Left Click to drag.
        ImagePut.gdiplusStartup()
        if (file) {
            pBitmap := ImagePutBitmap({ file: image, scale: ["auto", 150] })
        } else {
            pBitmap := ImagePutBitmap({ image: image, scale: ["auto", 150] })
        }
        DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", &width := 0)
        DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", &height := 0)
        display := this.Add("Text", options, text)
        display.imagehwnd := ImagePut.show(pBitmap, , [0, 0], WS_CHILD | WS_VISIBLE | WS_DISABLED, , display.hwnd)
        ImagePut.gdiplusShutdown()
        return display
    }
}

; Create the StatusOSD class
class OSD {
    static gui := ''
    static position := "topleft"
    static controls := Map()
    static mediaSessTimer := ''
    static mediaSession := ''
    static destroyTimer := 0
    static mediaData := {
        initialized: false,
        title: 'No Title',
        artist: 'No Artist',
        currentPostition: '16:06',
        length: '09:11',
        thumbnail: {
            data: 'anime.jpg',
            file: true
        }
    }
    static type := ''

    ; Show GUI
    static Show(type) {
        this.type := type
        if (!this.gui) {
            this.Initialize()
        }
        this.UpdateMediaSession()

        pos := PositionCalculator.GetPosition("topleft", appConfig.UI.Status.Width, appConfig.UI.Status.Height)
        this.gui.Show("x" pos.x " y" pos.y " w" appConfig.UI.Status.Width " h" appConfig.UI.Status.Height " NoActivate")

        ; Reset destroy timer
        if (this.destroyTimer != 0) {
            SetTimer this.destroyTimer, 0
        }
        this.destroyTimer := ObjBindMethod(this, "Destroy")
        SetTimer this.destroyTimer, -3000 ; Auto-destroy after 3 seconds
    }

    static Destroy() {
        this.StopMediaTimer()
        if this.gui {
            this.gui.Destroy()
            this.controls.Clear()
            this.gui := ''
        }
        this.destroyTimer := 0
    }

    ; Initialize GUI
    static Initialize() {
        this.gui := Gui2("+AlwaysOnTop -Resize -Caption +ToolWindow")
        this.gui.BackColor := "0x1C1C1C"
        WinSetTransparent(230, this.gui)

        ; Initialize controller
        if (this.mediaData.thumbnail.file) {
            this.controls['AlbumArt'] := this.gui.AddImage(this.mediaData.thumbnail.data, true, "x10 y10 w150 h150 Border")
        } else {
            this.controls['AlbumArt'] := this.gui.AddImage(this.mediaData.thumbnail.data.ptr, false, "x10 y10 w150 h150 Border")
        }
        this.controls['Row1'] := this.gui.AddText("x170 y10 w880 h25")
        this.controls['Row2'] := this.gui.AddText("x170 y35 w880 h25")
        this.controls['Row3'] := this.gui.AddText("x170 y60 w880 h25")

        this.controls['Row5'] := this.gui.AddText("x170 y110 w880 h25")
        this.controls['Row5-Arrow'] := this.gui.AddText("x315 y110 w880 h25")
        this.controls['Row5.1'] := this.gui.AddText("x350 y110 w880 h25")
        this.controls['Row5.1-Divider'] := this.gui.AddText("x420 y110 w880 h25")
        this.controls['Row5.2'] := this.gui.AddText("x440 y110 w880 h25")
        this.controls['Row5.2-Divider'] := this.gui.AddText("x510 y110 w880 h25")
        this.controls['Row5.3'] := this.gui.AddText("x530 y110 w880 h25")

        this.controls['Row6'] := this.gui.AddText("x255 y135 w880 h25")
        this.controls['Row6-Arrow'] := this.gui.AddText("x315 y135 w880 h25")
        this.controls['Row6.1'] := this.gui.AddText("x350 y135 w880 h25")
        this.controls['Row6.1-Divider'] := this.gui.AddText("x420 y135 w880 h25")
        this.controls['Row6.2'] := this.gui.AddText("x440 y135 w880 h25")
        this.controls['Row6.2-Divider'] := this.gui.AddText("x510 y135 w880 h25")
        this.controls['Row6.3'] := this.gui.AddText("x530 y135 w880 h25")

        ; Set styling
        this.controls['Row1'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row2'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row3'].SetFont("s14 cWhite", "Segoe UI Bold")

        this.controls['Row5'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row5-Arrow'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row5.1'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row5.1-Divider'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row5.2'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row5.2-Divider'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row5.3'].SetFont("s14 cWhite", "Segoe UI Bold")

        this.controls['Row6'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row6-Arrow'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row6.1'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row6.1-Divider'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row6.2'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row6.2-Divider'].SetFont("s14 cWhite", "Segoe UI Bold")
        this.controls['Row6.3'].SetFont("s14 cWhite", "Segoe UI Bold")

        ; Initialize Media Session Update
        if (!this.mediaSessTimer) {
            this.UpdateMediaSession()
            this.mediaSessTimer := ObjBindMethod(this, "UpdateMediaSession")
            SetTimer(this.mediaSessTimer, 250)
        }

        ; Initialize with value
        this.UpdateControllerValue()

        ; Set flag as initialized
        this.mediaData.initialized := true
    }

    static UpdateControllerValue() {
        if (!this.gui) {
            return
        }

        this.controls['Row1'].Value := this.type ' | ' this.mediaData.currentPostition '/' this.mediaData.length
        this.controls['Row2'].Value := this.mediaData.title
        this.controls['Row3'].Value := this.mediaData.artist

        this.controls['Row5'].Value := 'Volume - Device'
        this.controls['Row5-Arrow'].Value := ' => '
        this.controls['Row5.1'].Value := 'A1: ' appConfig.Audio.A1.Volume
        this.controls['Row5.1-Divider'].Value := ' | '
        this.controls['Row5.2'].Value := 'A2: ' appConfig.Audio.A2.Volume
        this.controls['Row5.2-Divider'].Value := ' | '
        this.controls['Row5.3'].Value := 'B1: ' appConfig.Audio.B1.Volume

        this.controls['Row6'].Value := 'App'
        this.controls['Row6-Arrow'].Value := ' => '
        this.controls['Row6.1'].Value := 'C1: ' appConfig.Audio.C1.Volume
        this.controls['Row6.1-Divider'].Value := ' | '
        this.controls['Row6.2'].Value := 'C2: ' appConfig.Audio.C2.Volume
        this.controls['Row6.2-Divider'].Value := ' | '
        this.controls['Row6.3'].Value := 'C3: ' appConfig.Audio.C3.Volume

        this.SetControllerColor()
    }

    static SetControllerColor() {
        if (appConfig.Audio.A1.Muted) {
            if (appConfig.Audio.CurrentOutput = appConfig.Audio.A1.Device) {
                this.controls['Row5.1'].SetFont("s14 cff9720", "Segoe UI Bold")
            } else {
                this.controls['Row5.1'].SetFont("s14 cRed", "Segoe UI Bold")
            }
        } else {
            if (appConfig.Audio.CurrentOutput = appConfig.Audio.A1.Device) {
                this.controls['Row5.1'].SetFont("s14 cLime", "Segoe UI Bold")
            } else {
                this.controls['Row5.1'].SetFont("s14 cwhite", "Segoe UI Bold")
            }
        }
        if (appConfig.Audio.A2.Muted) {
            if (appConfig.Audio.CurrentOutput = appConfig.Audio.A2.Device) {
                this.controls['Row5.2'].SetFont("s14 cff9720", "Segoe UI Bold")
            } else {
                this.controls['Row5.2'].SetFont("s14 cRed", "Segoe UI Bold")
            }
        } else {
            if (appConfig.Audio.CurrentOutput = appConfig.Audio.A2.Device) {
                this.controls['Row5.2'].SetFont("s14 cLime", "Segoe UI Bold")
            } else {
                this.controls['Row5.2'].SetFont("s14 cwhite", "Segoe UI Bold")
            }

        }
        if (appConfig.Audio.B1.Muted) {
            this.controls['Row5.3'].SetFont("s14 cRed", "Segoe UI Bold")
        } else {
            this.controls['Row5.3'].SetFont("s14 cwhite", "Segoe UI Bold")
        }
    }

    static SetRedraw(active) {
        Redraw := '-Redraw'
        if (active)
            Redraw := '+Redraw'

        this.controls['AlbumArt'].Opt(Redraw)
        this.controls['Row1'].Opt(Redraw)
        this.controls['Row2'].Opt(Redraw)
        this.controls['Row3'].Opt(Redraw)

        this.controls['Row5.1'].Opt(Redraw)
        this.controls['Row5.2'].Opt(Redraw)
        this.controls['Row5.3'].Opt(Redraw)

        this.controls['Row6.1'].Opt(Redraw)
        this.controls['Row6.2'].Opt(Redraw)
        this.controls['Row6.3'].Opt(Redraw)
    }

    ; Update Media Session
    static UpdateMediaSession() {
        try {
            this.mediaSession := Media.GetCurrentSession()
            this.mediaData.title := this.mediaSession.Title
            this.mediaData.artist := this.mediaSession.Artist
            this.mediaData.currentPostition := TimeFormatHMS(this.mediaSession.Position)
            this.mediaData.length := TimeFormatHMS(this.mediaSession.EndTime)
            this.mediaData.thumbnail.data := this.mediaSession.Thumbnail
            this.mediaData.thumbnail.file := false
        }
        catch {
            this.mediaSession := ''
            this.mediaData := {
                initialized: true,
                title: 'No Title',
                artist: 'No Artist',
                currentPostition: '--:--',
                length: '--:--',
                thumbnail: {
                    data: 'anime.jpg',
                    file: true
                }
            }
        }

        if (this.mediaData.initialized) {
            this.UpdateControllerValue()
        }
    }

    ; Stop Media Session Updater
    static StopMediaTimer() {
        SetTimer(this.mediaSessTimer, 0)
    }
}

ShowMidiSettings(*) {
    global midiSetting, appConfig

    midiSettingControls := Map()

    if (IsSet(midiSetting)) {
        midiSetting.Show()
        return
    }

    audioEndpointList := GetDeviceNames()

    ; Initialize GUI
    midiSetting := Gui("+AlwaysOnTop -Resize +Caption -ToolWindow", "MIDI to Macro Settings")
    midiSetting.BackColor := "0x1C1C1C"
    WinSetTransparent(230, midiSetting)

    fontSize := "s10"
    compHeight := "h30"

    ; Table Header for UI Section
    midiSetting.Add("Text", "x10 y10 w100 " compHeight, "UI").SetFont("s14 cWhite", "Segoe UI Bold")
    midiSetting.Add("Text", "x10 y40 w100 " compHeight, "Field").SetFont(fontSize " cWhite", "Segoe UI Bold")
    midiSetting.Add("Text", "x120 y40 w250 " compHeight, "Value").SetFont(fontSize " cWhite", "Segoe UI Bold")

    ; Table Header for Apps Section
    midiSetting.Add("Text", "x10 y230 w100 " compHeight, "Apps").SetFont("s14 cWhite", "Segoe UI Bold")
    midiSetting.Add("Text", "x10 y260 w100 " compHeight, "Category").SetFont(fontSize " cWhite", "Segoe UI Bold")
    midiSetting.Add("Text", "x120 y260 w250 " compHeight, "Apps (comma-separated)").SetFont(fontSize " cWhite", "Segoe UI Bold")

    ; Table Header for Audio Section
    midiSetting.Add("Text", "x10 y380 w100 " compHeight, "Audio").SetFont("s14 cWhite", "Segoe UI Bold")
    midiSetting.Add("Text", "x10 y410 w100 " compHeight, "Channel").SetFont(fontSize " cWhite", "Segoe UI Bold")
    midiSetting.Add("Text", "x120 y410 w250 " compHeight, "Device").SetFont(fontSize " cWhite", "Segoe UI Bold")

    ; Define Y-coordinate start for rows
    uiY := 70      ; Starting Y-coordinate for UI fields
    appsY := 290   ; Starting Y-coordinate for Apps fields
    audioY := 440  ; Starting Y-coordinate for Audio fields
    rowHeight := 30 ; Space between rows

    ; Helper function to add a UI row
    AddUIRow(FieldCode, FieldName, CurrentValue) {
        midiSetting.Add("Text", Format("x10 y{1} w100 " compHeight, uiY), FieldName).SetFont(fontSize " cWhite", "Segoe UI Bold")
        input := midiSetting.Add("Edit", Format("x120 y{1} w250", uiY), CurrentValue)
        input.OnEvent("Change", UpdateUIConfig.Bind(FieldCode))
        uiY += rowHeight
    }

    ; Helper function to add an Apps row
    AddAppsRow(CategoryName, CurrentApps) {
        midiSetting.Add("Text", Format("x10 y{1} w100 " compHeight, appsY), CategoryName).SetFont(fontSize " cWhite", "Segoe UI Bold")
        input := midiSetting.Add("Edit", Format("x120 y{1} w250 r2", appsY), CurrentApps) ; "r2" limits to 2 lines
        input.OnEvent("Change", UpdateAppsConfig.Bind(CategoryName))
        appsY += rowHeight * 1.5
    }

    ; Helper function to add an Audio row
    AddAudioRow(ChannelName, ChannelText, CurrentDevice) {
        midiSetting.Add("Text", Format("x10 y{1} w100 " compHeight, audioY), ChannelText).SetFont(fontSize " cWhite", "Segoe UI Bold")
        ddl := midiSetting.Add("DropDownList", Format("x120 y{1} w250", audioY), audioEndpointList)
        if (CurrentDevice != "") {
            ddl.Value := CurrentDevice
        }
        ddl.OnEvent("Change", UpdateAudioConfig.Bind(ChannelName))
        audioY += rowHeight
    }

    ; Add rows for UI fields
    AddUIRow("M", "Margin", appConfig.UI.Margin)
    AddUIRow("VW", "Volume Width", appConfig.UI.Volume.Width)
    AddUIRow("VH", "Volume Height", appConfig.UI.Volume.Height)
    AddUIRow("SW", "Status Width", appConfig.UI.Status.Width)
    AddUIRow("SH", "Status Height", appConfig.UI.Status.Height)

    ; Add rows for Apps fields
    AddAppsRow("Media", appConfig.Apps.Media)
    AddAppsRow("Social", appConfig.Apps.Social)

    ; Add rows for Audio fields
    AddAudioRow("A1", "A1 (Output)", appConfig.Audio.A1.Device)
    AddAudioRow("A2", "A2 (Output)", appConfig.Audio.A2.Device)
    AddAudioRow("B1", "B1 (Input)", appConfig.Audio.B1.Device)
    AddAudioRow("C1", "C1 (Media)", appConfig.Audio.C1.Device)
    AddAudioRow("C2", "C2 (Social)", appConfig.Audio.C2.Device)
    AddAudioRow("C3", "C3 (N/A)", appConfig.Audio.C3.Device)

    ; Show the table
    midiSetting.Show("AutoSize xCenter")
}