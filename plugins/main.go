package main

/*
#include <stdlib.h>

typedef void (*KeyCallback)(const char*);

static inline void bridge_key_callback(KeyCallback cb, const char* event) {
    cb(event);
}
*/
import "C"

import (
	"encoding/json"
	"sync"
	"unsafe"

	hook "github.com/robotn/gohook"
	psnet "github.com/shirou/gopsutil/v3/net"
)

var (
	mu      sync.Mutex
	running bool
	stopCh  chan struct{}
	keyCb   C.KeyCallback
)

var keyNames = map[uint16]string{
	8: "Backspace", 9: "Tab", 13: "Enter", 16: "Shift", 17: "Ctrl",
	18: "Alt", 19: "Pause", 20: "CapsLock", 27: "Escape", 32: "Space",
	33: "PageUp", 34: "PageDown", 35: "End", 36: "Home",
	37: "Left", 38: "Up", 39: "Right", 40: "Down",
	45: "Insert", 46: "Delete",
	91: "Win", 92: "Win", 93: "Menu",
	112: "F1", 113: "F2", 114: "F3", 115: "F4", 116: "F5", 117: "F6",
	118: "F7", 119: "F8", 120: "F9", 121: "F10", 122: "F11", 123: "F12",
	144: "NumLock", 145: "ScrollLock",
	186: ";", 187: "=", 188: ",", 189: "-", 190: ".", 191: "/", 192: "`",
	219: "[", 220: "\\", 221: "]", 222: "'",
}

func resolveKeyName(rawcode uint16, keychar rune) string {
	if name, ok := keyNames[rawcode]; ok {
		return name
	}
	if keychar > 0 && keychar != 0xFFFF {
		return string(keychar)
	}
	if rawcode >= 0x30 && rawcode <= 0x39 {
		return string(rune(rawcode))
	}
	if rawcode >= 0x41 && rawcode <= 0x5A {
		return string(rune(rawcode))
	}
	if rawcode >= 0x60 && rawcode <= 0x69 {
		return "Num" + string(rune(rawcode-0x60+'0'))
	}
	return "0x" + uitoa(rawcode)
}

func uitoa(v uint16) string {
	const hex = "0123456789ABCDEF"
	return string([]byte{hex[v>>12&0xF], hex[v>>8&0xF], hex[v>>4&0xF], hex[v&0xF]})
}

//export RegisterKeyCallback
func RegisterKeyCallback(cb C.KeyCallback) {
	mu.Lock()
	defer mu.Unlock()
	keyCb = cb
}

//export StartKeyListener
func StartKeyListener() {
	mu.Lock()
	if running {
		mu.Unlock()
		return
	}
	running = true
	stopCh = make(chan struct{})
	mu.Unlock()

	go func() {
		evChan := hook.Start()
		defer hook.End()

		for {
			select {
			case <-stopCh:
				return
			case ev, ok := <-evChan:
				if !ok {
					return
				}
				if ev.Kind != hook.KeyUp {
					continue
				}
				name := resolveKeyName(ev.Rawcode, rune(ev.Keychar))
				entry := "up:" + name

				mu.Lock()
				cb := keyCb
				mu.Unlock()

				if cb != nil {
					cstr := C.CString(entry)
					C.bridge_key_callback(cb, cstr)
				}
			}
		}
	}()
}

//export StopKeyListener
func StopKeyListener() {
	mu.Lock()
	defer mu.Unlock()
	if !running {
		return
	}
	running = false
	keyCb = nil
	close(stopCh)
}

//export FreeString
func FreeString(s *C.char) {
	C.free(unsafe.Pointer(s))
}

//export GetNetStats
func GetNetStats() *C.char {
	stats, err := psnet.IOCounters(false)
	if err != nil || len(stats) == 0 {
		return C.CString(`{"bytes_sent":0,"bytes_recv":0}`)
	}
	type payload struct {
		BytesSent uint64 `json:"bytes_sent"`
		BytesRecv uint64 `json:"bytes_recv"`
	}
	data, err := json.Marshal(payload{BytesSent: stats[0].BytesSent, BytesRecv: stats[0].BytesRecv})
	if err != nil {
		return C.CString(`{"bytes_sent":0,"bytes_recv":0}`)
	}
	return C.CString(string(data))
}

func main() {}
