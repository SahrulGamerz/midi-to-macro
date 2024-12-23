#Requires AutoHotkey v2
#Include Config.ahk

global appConfig

configFileName := "MidiToMacro.ini"

Class MidiToMacroConfig {
	__New() {
		this.maxLogLines := 10
		this.midiInDevice := -1
		this.midiInDeviceName := ""
		this.showOnStartup := true
		this.Audio := AudioConfig()
		this.UI := UIConfig()
		this.Apps := AppsConfig()
	}
}

Class AudioConfig {
	__New() {
		this.CurrentOutput := 1
		this.SetTimer := -150
		this.A1 := BaseAudioConfig()
		this.A2 := BaseAudioConfig()
		this.B1 := BaseAudioConfig()
		this.C1 := BaseAudioConfig()
		this.C2 := BaseAudioConfig()
		this.C3 := BaseAudioConfig()
	}
}

Class BaseAudioConfig {
	__New() {
		this.Device := ""
		this.Volume := 100
		this.Muted := 0
	}
}

Class UIConfig {
	__New() {
		this.Margin := 20
		this.Volume := BaseUIConfig(310, 80)
		this.Status := BaseUIConfig(900, 170)
	}
}

Class BaseUIConfig {
	__New(width, height) {
		this.Width := width
		this.Height := height
	}
}

Class AppsConfig {
	__New() {
		this.Media := "spotify.exe, chrome.exe, msedge.exe, firefox.exe, Microsoft.Media.Player.exe"
		this.Social := "discord.exe"
	}
}

appConfig := MidiToMacroConfig()

ReadConfig() {
	if (FileExist(configFileName)) {
		; Read General Settings
		appConfig.maxLogLines := IniRead(configFileName, "Settings", "MaxLogLines", 10)
		appConfig.midiInDevice := IniRead(configFileName, "Settings", "MidiInDevice", -1)
		appConfig.midiInDeviceName := IniRead(configFileName, "Settings", "MidiInDeviceName", "")
		appConfig.showOnStartup := IniRead(configFileName, "Settings", "ShowOnStartup", true)

		; Read Audio settings with defaults from the AudioConfig class
		appConfig.Audio.CurrentOutput := IniRead(configFileName, "Settings.Audio", "CurrentOutput", appConfig.Audio.CurrentOutput)
		appConfig.Audio.SetTimer := IniRead(configFileName, "Settings.Audio", "SetTimer", appConfig.Audio.SetTimer)
	
		; Read Audio channel settings (A1, A2, B1, etc.) with defaults from the BaseAudioConfig class
		appConfig.Audio.A1.Device := IniRead(configFileName, "Settings.Audio.A1", "Device", appConfig.Audio.A1.Device)
		appConfig.Audio.A1.Volume := IniRead(configFileName, "Settings.Audio.A1", "Volume", appConfig.Audio.A1.Volume)
		appConfig.Audio.A1.Muted := IniRead(configFileName, "Settings.Audio.A1", "Muted", appConfig.Audio.A1.Muted)
		
		appConfig.Audio.A2.Device := IniRead(configFileName, "Settings.Audio.A2", "Device", appConfig.Audio.A2.Device)
		appConfig.Audio.A2.Volume := IniRead(configFileName, "Settings.Audio.A2", "Volume", appConfig.Audio.A2.Volume)
		appConfig.Audio.A2.Muted := IniRead(configFileName, "Settings.Audio.A2", "Muted", appConfig.Audio.A2.Muted)
		
		appConfig.Audio.B1.Device := IniRead(configFileName, "Settings.Audio.B1", "Device", appConfig.Audio.B1.Device)
		appConfig.Audio.B1.Volume := IniRead(configFileName, "Settings.Audio.B1", "Volume", appConfig.Audio.B1.Volume)
		appConfig.Audio.B1.Muted := IniRead(configFileName, "Settings.Audio.B1", "Muted", appConfig.Audio.B1.Muted)
		
		appConfig.Audio.C1.Device := IniRead(configFileName, "Settings.Audio.C1", "Device", appConfig.Audio.C1.Device)
		appConfig.Audio.C1.Volume := IniRead(configFileName, "Settings.Audio.C1", "Volume", appConfig.Audio.C1.Volume)
		appConfig.Audio.C1.Muted := IniRead(configFileName, "Settings.Audio.C1", "Muted", appConfig.Audio.C1.Muted)
		
		appConfig.Audio.C2.Device := IniRead(configFileName, "Settings.Audio.C2", "Device", appConfig.Audio.C2.Device)
		appConfig.Audio.C2.Volume := IniRead(configFileName, "Settings.Audio.C2", "Volume", appConfig.Audio.C2.Volume)
		appConfig.Audio.C2.Muted := IniRead(configFileName, "Settings.Audio.C2", "Muted", appConfig.Audio.C2.Muted)
		
		appConfig.Audio.C3.Device := IniRead(configFileName, "Settings.Audio.C3", "Device", appConfig.Audio.C3.Device)
		appConfig.Audio.C3.Volume := IniRead(configFileName, "Settings.Audio.C3", "Volume", appConfig.Audio.C3.Volume)
		appConfig.Audio.C3.Muted := IniRead(configFileName, "Settings.Audio.C3", "Muted", appConfig.Audio.C3.Muted)

		; Read UI Settings with defaults from the UIConfig class
		appConfig.UI.Margin := IniRead(configFileName, "Settings.UI", "Margin", appConfig.UI.Margin)
		appConfig.UI.Volume.Width := IniRead(configFileName, "Settings.UI.Volume", "Width", appConfig.UI.Volume.Width)
		appConfig.UI.Volume.Height := IniRead(configFileName, "Settings.UI.Volume", "Height", appConfig.UI.Volume.Height)
		appConfig.UI.Status.Width := IniRead(configFileName, "Settings.UI.Status", "Width", appConfig.UI.Status.Width)
		appConfig.UI.Status.Height := IniRead(configFileName, "Settings.UI.Status", "Height", appConfig.UI.Status.Height)
	
		; Read Apps settings with defaults from the AppsConfig class
		appConfig.Apps.Media := IniRead(configFileName, "Settings.Apps", "Media", appConfig.Apps.Media)
		appConfig.Apps.Social := IniRead(configFileName, "Settings.Apps", "Social", appConfig.Apps.Social)
	} else {
		WriteConfigAudio()
		WriteConfigUI()
		WriteConfigApps()
	}
}

WriteConfigMidiDevice(midiInDevice, midiInDeviceName) {
	IniWrite(midiInDevice, configFileName, "Settings", "MidiInDevice")
	IniWrite(midiInDeviceName, configFileName, "Settings", "MidiInDeviceName")
	appConfig.midiInDevice := midiInDevice
	appConfig.midiInDeviceName := midiInDeviceName
}

WriteConfigShowOnStartup(showOnStartup) {
	IniWrite(showOnStartup, configFileName, "Settings", "ShowOnStartup")
	appConfig.showOnStartup := showOnStartup
}

WriteConfigAudio() {
	IniWrite(appConfig.Audio.CurrentOutput, configFileName, "Settings.Audio", "CurrentOutput")
	IniWrite(appConfig.Audio.SetTimer, configFileName, "Settings.Audio", "SetTimer")

	IniWrite(appConfig.Audio.A1.Device, configFileName, "Settings.Audio.A1", "Device")
	IniWrite(appConfig.Audio.A1.Volume, configFileName, "Settings.Audio.A1", "Volume")
	IniWrite(appConfig.Audio.A1.Muted, configFileName, "Settings.Audio.A1", "Muted")
	
	IniWrite(appConfig.Audio.A2.Device, configFileName, "Settings.Audio.A2", "Device")
	IniWrite(appConfig.Audio.A2.Volume, configFileName, "Settings.Audio.A2", "Volume")
	IniWrite(appConfig.Audio.A2.Muted, configFileName, "Settings.Audio.A2", "Muted")
	
	IniWrite(appConfig.Audio.B1.Device, configFileName, "Settings.Audio.B1", "Device")
	IniWrite(appConfig.Audio.B1.Volume, configFileName, "Settings.Audio.B1", "Volume")
	IniWrite(appConfig.Audio.B1.Muted, configFileName, "Settings.Audio.B1", "Muted")
	
	IniWrite(appConfig.Audio.C1.Device, configFileName, "Settings.Audio.C1", "Device")
	IniWrite(appConfig.Audio.C1.Volume, configFileName, "Settings.Audio.C1", "Volume")
	IniWrite(appConfig.Audio.C1.Muted, configFileName, "Settings.Audio.C1", "Muted")
	
	IniWrite(appConfig.Audio.C2.Device, configFileName, "Settings.Audio.C2", "Device")
	IniWrite(appConfig.Audio.C2.Volume, configFileName, "Settings.Audio.C2", "Volume")
	IniWrite(appConfig.Audio.C2.Muted, configFileName, "Settings.Audio.C2", "Muted")
	
	IniWrite(appConfig.Audio.C3.Device, configFileName, "Settings.Audio.C3", "Device")
	IniWrite(appConfig.Audio.C3.Volume, configFileName, "Settings.Audio.C3", "Volume")
	IniWrite(appConfig.Audio.C3.Muted, configFileName, "Settings.Audio.C3", "Muted")
}

WriteConfigUI() {
	IniWrite(appConfig.UI.Margin, configFileName, "Settings.UI", "Margin")

	IniWrite(appConfig.UI.Volume.Width, configFileName, "Settings.UI.Volume", "Width")
	IniWrite(appConfig.UI.Volume.Height, configFileName, "Settings.UI.Volume", "Height")

	IniWrite(appConfig.UI.Status.Width, configFileName, "Settings.UI.Status", "Width")
	IniWrite(appConfig.UI.Status.Height, configFileName, "Settings.UI.Status", "Height")
}

WriteConfigApps() {
	IniWrite(appConfig.Apps.Media, configFileName, "Settings.Apps", "Media")
	IniWrite(appConfig.Apps.Social, configFileName, "Settings.Apps", "Social")
}

UpdateAudioConfig(ChannelName, Ctrl, *) {
	if (ChannelName = "A1") {
		appConfig.Audio.A1.Device := Ctrl.Value
	}
	else if (ChannelName = "A2") {
		appConfig.Audio.A2.Device := Ctrl.Value
	}
	else if (ChannelName = "B1") {
		appConfig.Audio.B1.Device := Ctrl.Value
	}
	else if (ChannelName = "C1") {
		appConfig.Audio.C1.Device := Ctrl.Value
	}
	else if (ChannelName = "C2") {
		appConfig.Audio.C2.Device := Ctrl.Value
	}
	else if (ChannelName = "C3") {
		appConfig.Audio.C3.Device := Ctrl.Value
	}
	
	WriteConfigAudio()
}

UpdateAppsConfig(Category, Ctrl, *) {
	if (Category = "Media") {
		appConfig.Apps.Media := Ctrl.Value
	}
	else if (Category = "Social") {
		appConfig.Apps.Social := Ctrl.Value
	}

	WriteConfigApps()
}

UpdateUIConfig(Field, Ctrl, *) {
	if (Field = "M") {
		appConfig.UI.Margin := Ctrl.Value
	}
	else if (Field = "VW") {
		appConfig.UI.Volume.Width := Ctrl.Value
	}
	else if (Field = "VH") {
		appConfig.UI.Volume.Height := Ctrl.Value
	}
	else if (Field = "SW") {
		appConfig.UI.Status.Width := Ctrl.Value
	}
	else if (Field = "SH") {
		appConfig.UI.Status.Height := Ctrl.Value
	}

	WriteConfigUI()
}