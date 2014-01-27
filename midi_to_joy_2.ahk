/* 

MIDI to joy.
Based on GENERIC MIDI APP V.0.6 by genmce and contributors.

Edit the "VARIBLES TO SET @ STARTUP" section.

MidiRules.ahk contains the logic that maps from MIDI controllers to VJoy.


Sections with !!!!!!!!!!!!!!!!!!!! - don't edit between these, unless you know what you are doing (uykwyad) !  

Sections with ++++++++++++++++++++ Edit between these marks. You won't break it, I don't think???
 
*/
 
#Include VJoy_lib.ahk 
#Include mtjFunctions.ahk 

#Persistent
#SingleInstance
SendMode Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

if A_OSVersion in WIN_NT4,WIN_95,WIN_98,WIN_ME  ; if not xp or 2000 quit
{
    MsgBox This script requires Windows 2000/XP or later.
    ExitApp
}

version = midi_to_joy_2        
VJoy_Init()
gosub VJoyInitMaxValues
readini()                       ; load values from the ini file, via the readini function - see Midi_under_the_hood.ahk file
gosub, MidiPortRefresh          ; used to refresh the input and output port lists - see Midi_under_the_hood.ahk file
port_test(numports,numports2)   ; test the ports - check for valid ports? - see Midi_under_the_hood.ahk file
gosub, midiin_go                ; opens the midi input port listening routine see Midi_under_the_hood.ahk file
gosub, midiout                  ; opens the midi out port see Midi_under_the_hood.ahk file  
gosub, midiMon                  ; see below - a monitor gui - see Midi_In_and_GuiMonitor.ahk

;*************************************************
;*         VARIBLES TO SET @ STARTUP
;*************************************************

#Include UserVariables.ahk

return

VJoyInitMaxValues:
    global AxisMax_X, AxisMax_Y, AxisMax_Z, AxisMax_RX, AxisMax_RY, AxisMax_RZ, AxisMax_SL0, AxisMax_SL1, AxisMax_WHL
    AxisMax_X  := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_X)
    AxisMax_Y  := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_Y)
    AxisMax_Z  := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_Z)
    AxisMax_RX := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_RX)
    AxisMax_RY := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_RY)
    AxisMax_RZ := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_RZ)
    AxisMax_SL0 := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_SL0)
    AxisMax_SL1 := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_SL1)
    AxisMax_WHL := VJoy_GetVJDAxisMax(iInterface, HID_USAGE_WHL)
return

#Include Midi_In_and_GuiMonitor.ahk ; this file contains: the function to parse midi message into parts we can work with and a midi monitor.
#Include MidiRules.ahk              ; this file contains: Rules for manipulating midi input then sending modified midi output.
#Include Midi_under_the_hood.ahk    ; this file contains: (DO NOT EDIT THIS FILE) all the dialogs to set up midi ports and midi message handling.