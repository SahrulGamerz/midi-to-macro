#Requires AutoHotkey v2

;*************************************************
;*          RULES - MIDI FILTERS
;*************************************************

/*
	The MidiRules section is for mapping MIDI input to actions.
	Alter these functions as required.
*/

global MediaAppsVolumeObject, SocialAppsVolumeObject

MediaAppsVolumeObject := 0
SocialAppsVolumeObject := 0

ProcessNote(device, channel, note, velocity, isNoteOn) {
	global appConfig, AudioEndpointsList

	if (channel != 1) {
		return
	}

	if (channel = 1 and velocity = 127) {
		return
	}

	Device := ""
	Muted := ""

	if(note = 0) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.A1.Device]
		Device := AudioEndpoint['Name']
		Muted := SoundGetMute('', Device)
		appConfig.Audio.A1.Muted := !Muted
	} else if(note = 11) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.A2.Device]
		Device := AudioEndpoint['Name']
		Muted := SoundGetMute('', Device)
		appConfig.Audio.A2.Muted := !Muted
	} else if(note = 10) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.B1.Device]
		Device := AudioEndpoint['Name']
		Muted := SoundGetMute('', Device)
		appConfig.Audio.B1.Muted := !Muted
	} else if(note = 9) {
		if (appConfig.Audio.CurrentOutput = appConfig.Audio.A2.Device) {
			appConfig.Audio.CurrentOutput := appConfig.Audio.A1.Device
		} else {
			appConfig.Audio.CurrentOutput := appConfig.Audio.A2.Device
		}

		AudioEndpoint := AudioEndpointsList[appConfig.Audio.CurrentOutput]
		Device := AudioEndpoint['ID']
		OSD.Show('Media Output')
		SetAudioDeviceForAllApps(appConfig.Apps.Media, Device, appConfig.Audio.C1.Volume)
	} else if(note = 8) {
		DisplayOutput("Media", "Previous")
		OSD.Show('⏮️ Previous')
		Send("{Media_Prev}")
	} else if(note = 7) {
		DisplayOutput("Media", "Play/Pause")
		type := '⏯️ Play/Pause'
		if(OSD.mediaSession) {
			if (OSD.mediaSession.PlaybackStatus = 4) {
				type := '⏸ Paused'
			} else if (OSD.mediaSession.PlaybackStatus = 5) {
				type := '▶️ Playing'
			}
		}
		OSD.Show(type)
		Send("{Media_Play_Pause}")
	} else if(note = 6) {
		DisplayOutput("Media", "Stop")
		OSD.Show('⏹️ Stop')
		Send("{Media_Stop}")
	} else if(note = 5) {
		DisplayOutput("Media", "Next")
		OSD.Show('⏭️ Next')
		Send("{Media_Next}")
	} else if(note = 4) {
	
	} else if(note = 3) {
	
	} else if(note = 2) {
	
	} else if(note = 1) {
	
	}

	WriteConfigAudio()

	if(Device = "" Or Muted = "") {
		return
	}

	SoundSetMute(!Muted, '', Device)
	DisplayOutput("Volume " . Device, !Muted ? 'Mute' : 'Unmute')
	OSD.Show(Device ' ' (!Muted ? 'Muted' : 'Unmuted'))
}

ProcessCC(device, channel, cc, value) {
	global appConfig, AudioEndpointsList, MediaAppsVolumeObject, SocialAppsVolumeObject

	if (channel != 1) {
		return
	}

	ScaledValue := ConvertCCValueToScale(value, 0, 127)
	Volume := ScaledValue * 100
	Component := ''
	Device := ''
	if (cc = 16) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.A1.Device]
		Device := AudioEndpoint['Name']
		appConfig.Audio.A1.Volume := Round(Volume)
	} else if (cc = 14) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.A2.Device]
		Device := AudioEndpoint['Name']
		appConfig.Audio.A2.Volume := Round(Volume)
	} else if (cc = 19) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.B1.Device]
		Device := AudioEndpoint['Name']
		appConfig.Audio.B1.Volume := Round(Volume)
	} else if (cc = 17) {
		; Reset volume change timer
		if (MediaAppsVolumeObject != 0) {
			SetTimer MediaAppsVolumeObject, 0
		}

		appConfig.Audio.C1.Volume := Round(Volume)
		MediaAppsVolumeObject := SetVolumeForAllApps.Bind(appConfig.Apps.Media, Volume)
		SetTimer MediaAppsVolumeObject, appConfig.Audio.SetTimer
		; VolumeOSD.Show('Media', Volume)
		OSD.Show('Media Volume')
	} else if (cc = 15) {
		; Reset volume change timer
		if (SocialAppsVolumeObject != 0) {
			SetTimer SocialAppsVolumeObject, 0
		}

		appConfig.Audio.C2.Volume := Round(Volume)
		SocialAppsVolumeObject := SetVolumeForAllApps.Bind(appConfig.Apps.Social, Volume)
		SetTimer SocialAppsVolumeObject, appConfig.Audio.SetTimer
		; VolumeOSD.Show('Social', Volume)
		OSD.Show('Social Volume')
	} else if (cc = 18) {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.C3.Device]
		Device := AudioEndpoint['Name']
		appConfig.Audio.C3.Volume := Round(Volume)
	}

	WriteConfigAudio()

	if (Device = '') {
		return
	}

	SoundSetVolume(Volume, Component, Device)
	DisplayOutput("Volume " . Device, Format('{1:.2f}', Volume))
	; VolumeOSD.Show(Device, Volume)
	OSD.Show(Device ' Volume')
}

ProcessPC(device, channel, note, velocity) {

}

ProcessPitchBend(device, channel, value) {
	
}

SetAudioDeviceForAllApps(apps, deviceName, volume) {
	; Loop through each app and set its audio device
	appList := StrSplit(apps, ",")
	for _, app in appList {
		processName := Trim(app)

		; Check if process exists
		if ProcessExist(processName) {
			try {
				RunWait 'SoundVolumeView.exe /SetAppDefault "' deviceName '" all "' processName '"'
				RunWait 'SoundVolumeView.exe /SetVolume "' processName '" ' volume
				DisplayOutput("App Output", processName ' > ' deviceName)
			} catch Error as e {
				DisplayOutput("App Output", 'Failed: ' processName ' > ' deviceName)
			}
		} else {
			DisplayOutput("App Output", 'Process not found: ' processName)
		}
	}
}

SetVolumeForAllApps(apps, Volume) {
	; Loop through each app and set its audio device
	appList := StrSplit(apps, ",")
	for _, app in appList {
		processName := Trim(app)

		; Check if process exists
		if ProcessExist(processName) {
			try {
				RunWait 'SoundVolumeView.exe /SetVolume "' processName '" ' Volume
				DisplayOutput("App Volume", processName ' > ' Volume)
			} catch Error as e {
				DisplayOutput("App Output", 'Failed: ' processName ' > ' Volume)
			}
		} else {
			DisplayOutput("App Output", 'Process not found: ' processName)
		}
	}
}

UpdateOnStart() {
	global appConfig, AudioEndpointsList

	if (appConfig.Audio.A1.Device != "") {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.A1.Device]
		SoundSetVolume(appConfig.Audio.A1.Volume, '', AudioEndpoint['Name'])
		SoundSetMute(appConfig.Audio.A1.Muted, '', AudioEndpoint['Name'])
	}
	
	if (appConfig.Audio.A2.Device != "") {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.A2.Device]
		SoundSetVolume(appConfig.Audio.A2.Volume, '', AudioEndpoint['Name'])
		SoundSetMute(appConfig.Audio.A2.Muted, '', AudioEndpoint['Name'])
	}
	
	if (appConfig.Audio.B1.Device != "") {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.B1.Device]
		SoundSetVolume(appConfig.Audio.B1.Volume, '', AudioEndpoint['Name'])
		SoundSetMute(appConfig.Audio.B1.Muted, '', AudioEndpoint['Name'])
	}
	
	if (appConfig.Audio.C3.Device != "") {
		AudioEndpoint := AudioEndpointsList[appConfig.Audio.C3.Device]
		SoundSetVolume(appConfig.Audio.C3.Volume, '', AudioEndpoint['Name'])
		SoundSetMute(appConfig.Audio.C3.Muted, '', AudioEndpoint['Name'])
	}

	if (appConfig.Audio.CurrentOutput = "") {
		appConfig.Audio.CurrentOutput := 1
	}

	AudioEndpoint := AudioEndpointsList[appConfig.Audio.CurrentOutput]
	Device := AudioEndpoint['ID']

	SetAudioDeviceForAllApps(appConfig.Apps.Media, Device, appConfig.Audio.C1.Volume)
	SetVolumeForAllApps(appConfig.Apps.Social, appConfig.Audio.C2.Volume)

	OSD.Show('Started')
}