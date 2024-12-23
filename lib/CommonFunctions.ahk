#Requires AutoHotkey v2

global AudioEndpointsList

AudioEndpointsList := EnumAudioEndpoints()

ConvertCCValueToScale(value, minimum_value, maximum_value) {
	if (value > maximum_value) {
		value := maximum_value
	} else if (value < minimum_value) {
		value := minimum_value
	}
	return (value - minimum_value) / (maximum_value - minimum_value)
}

EnumAudioEndpoints(DataFlow := 2, StateMask := 1)
{
	_List := []

	; IMMDeviceEnumerator interface.
	; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nn-mmdeviceapi-immdeviceenumerator
	IMMDeviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")

	; IMMDeviceEnumerator::EnumAudioEndpoints method.
	; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdeviceenumerator-enumaudioendpoints
	ComCall(3, IMMDeviceEnumerator, "UInt", DataFlow, "UInt", StateMask, "UPtrP", &IMMDeviceCollection := 0)

	; IMMDeviceCollection::GetCount method.
	; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevicecollection-getcount
	ComCall(3, IMMDeviceCollection, "UIntP", &DevCount := 0)  ; Retrieves a count of the devices in the device collection.

	loop DevCount
	{
		_List.Push(Device := Map())

		; IMMDeviceCollection::Item method.
		; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevicecollection-item
		ComCall(4, IMMDeviceCollection, "UInt", A_Index - 1, "UPtrP", &IMMDevice := 0)

		; IMMDevice::GetId method.
		; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevice-getid
		ComCall(5, IMMDevice, "PtrP", &pBuffer := 0)
		Device["ID"] := StrGet(pBuffer)
		DllCall("Ole32.dll\CoTaskMemFree", "UPtr", pBuffer)

		; MMDevice::OpenPropertyStore method.
		; https://docs.microsoft.com/en-us/windows/win32/api/mmdeviceapi/nf-mmdeviceapi-immdevice-openpropertystore
		ComCall(4, IMMDevice, "UInt", 0x00000000, "UPtrP", &IPropertyStore := 0)

		Device["Name"] := GetDeviceProp(IPropertyStore, "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", 14)

		ObjRelease(IPropertyStore)
		ObjRelease(IMMDevice)
	}

	ObjRelease(IMMDeviceCollection)

	return _List
}

GetDeviceNameByID(DeviceID) {
    global AudioEndpointsList
    for _, device in AudioEndpointsList {
        if (device["ID"] = DeviceID) {
            return device["Name"]
        }
    }
    return "" ; Return empty string if no match found
}

GetDeviceNames() {
    global AudioEndpointsList
    deviceNames := []
    for _, device in AudioEndpointsList {
        deviceNames.Push(device["Name"])
    }
    return deviceNames
}

SetDefaultEndpoint(DeviceID, Role := 3)
{
	; Undocumented COM-interface IPolicyConfig.
	IPolicyConfig := ComObject("{870AF99C-171D-4F9E-AF0D-E63Df40c2BC9}", "{F8679F50-850A-41CF-9C72-430F290290C8}")
	if (Role & 0x1)
		ComCall(13, IPolicyConfig, "Str", DeviceID, "Int", 0)  ; Default Device
	if (Role & 0x2)
		ComCall(13, IPolicyConfig, "Str", DeviceID, "Int", 2)  ; Default Communication Device
}

InitDeviceProp(clsid, n)
{
	clsid := CLSIDFromString(clsid, Buffer(16 + 4))
	NumPut("Int", n, clsid, 16)
	return clsid
}

GetDeviceProp(ptr, clsid, n)
{
	; IPropertyStore::GetValue method.
	; https://docs.microsoft.com/en-us/windows/win32/api/propsys/nf-propsys-ipropertystore-getvalue
	ComCall(5, ptr, "Ptr", InitDeviceProp(clsid, n), "Ptr", pvar := PropVariant())
	return String(pvar)
}

GetDeviceID(list, name)
{
	for _device in list
		if InStr(_device["Name"], name)
			return _device["ID"]
	throw
}

CLSIDFromString(Str, Buffer := 0)
{
	if (!Buffer)
		Buffer := Buffer(16)
	DllCall("Ole32\CLSIDFromString", "Str", Str, "Ptr", Buffer, "HRESULT")
	return Buffer
}

class PropVariant
{
	__New()
	{
		this.buffer := Buffer(A_PtrSize == 4 ? 16 : 24)
		this.ptr := this.buffer.ptr
		this.size := this.buffer.size
	}

	__Delete()
	{
		DllCall("Ole32\PropVariantClear", "Ptr", this.ptr, "HRESULT")
	}

	ToString()
	{
		return StrGet(NumGet(this.ptr, 8, "UPtr"))  ; LPWSTR PROPVARIANT.pwszVal
	}
}

TimeFormatHMS(seconds) {
    secs := Format("{:02i}", mod(seconds, 60))
    mins := Format("{:02i}", Floor(seconds / 60))
    hours := Format("{:02i}", Floor(seconds / 60 / 60))

    if (hours = 0) {
        return mins ":" secs
    }
    return hours ":" mins ":" secs
}