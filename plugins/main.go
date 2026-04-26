package main

/*
#include <stdlib.h>
#include <windows.h>

typedef void (*KeyCallback)(const char*);

static inline void bridge_key_callback(KeyCallback cb, const char* event) {
    cb(event);
}

static DWORD getActiveWindowPid() {
    HWND hwnd = GetForegroundWindow();
    if (hwnd == NULL) return 0;
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    return pid;
}
*/
import "C"

import (
	"encoding/json"
	"os"
	"sort"
	"strings"
	"sync"
	"unsafe"

	"github.com/go-vgo/robotgo"
	hook "github.com/robotn/gohook"
	pscpu "github.com/shirou/gopsutil/v3/cpu"
	psdisk "github.com/shirou/gopsutil/v3/disk"
	pshost "github.com/shirou/gopsutil/v3/host"
	psmem "github.com/shirou/gopsutil/v3/mem"
	psnet "github.com/shirou/gopsutil/v3/net"
	psprocess "github.com/shirou/gopsutil/v3/process"
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

//export GetSystemStats
func GetSystemStats() *C.char {
	type diskInfo struct {
		Path        string  `json:"path"`
		Total       uint64  `json:"total"`
		Used        uint64  `json:"used"`
		Free        uint64  `json:"free"`
		UsedPercent float64 `json:"usedPercent"`
		Fstype      string  `json:"fstype"`
	}
	type netIface struct {
		Name  string   `json:"name"`
		Addrs []string `json:"addrs"`
		Flags []string `json:"flags"`
	}
	type payload struct {
		Uptime     uint64     `json:"uptime"`
		Platform   string     `json:"platform"`
		Hostname   string     `json:"hostname"`
		MemTotal   uint64     `json:"memTotal"`
		MemUsed    uint64     `json:"memUsed"`
		MemPercent float64    `json:"memPercent"`
		CpuPercent float64    `json:"cpuPercent"`
		Disks      []diskInfo `json:"disks"`
		NetIfaces  []netIface `json:"netIfaces"`
	}

	var p payload

	if uptime, err := pshost.Uptime(); err == nil {
		p.Uptime = uptime
	}
	if info, err := pshost.Info(); err == nil {
		p.Platform = info.Platform + " " + info.PlatformVersion
		p.Hostname = info.Hostname
	}
	if vm, err := psmem.VirtualMemory(); err == nil {
		p.MemTotal = vm.Total
		p.MemUsed = vm.Used
		p.MemPercent = vm.UsedPercent
	}
	if pcts, err := pscpu.Percent(0, false); err == nil && len(pcts) > 0 {
		p.CpuPercent = pcts[0]
	}
	if parts, err := psdisk.Partitions(false); err == nil {
		for _, part := range parts {
			if u, err := psdisk.Usage(part.Mountpoint); err == nil {
				p.Disks = append(p.Disks, diskInfo{
					Path:        u.Path,
					Total:       u.Total,
					Used:        u.Used,
					Free:        u.Free,
					UsedPercent: u.UsedPercent,
					Fstype:      u.Fstype,
				})
			}
		}
	}
	if ifaces, err := psnet.Interfaces(); err == nil {
		for _, iface := range ifaces {
			ni := netIface{Name: iface.Name}
			for _, addr := range iface.Addrs {
				ni.Addrs = append(ni.Addrs, addr.Addr)
			}
			for _, flag := range iface.Flags {
				ni.Flags = append(ni.Flags, flag)
			}
			p.NetIfaces = append(p.NetIfaces, ni)
		}
	}

	data, err := json.Marshal(p)
	if err != nil {
		return C.CString(`{}`)
	}
	return C.CString(string(data))
}

//export GetEnvVars
func GetEnvVars() *C.char {
	type envVar struct {
		Key   string `json:"key"`
		Value string `json:"value"`
	}
	raw := os.Environ()
	vars := make([]envVar, 0, len(raw))
	for _, e := range raw {
		idx := strings.IndexByte(e, '=')
		if idx < 0 {
			continue
		}
		vars = append(vars, envVar{Key: e[:idx], Value: e[idx+1:]})
	}
	sort.Slice(vars, func(i, j int) bool {
		return strings.ToLower(vars[i].Key) < strings.ToLower(vars[j].Key)
	})
	data, err := json.Marshal(vars)
	if err != nil {
		return C.CString(`[]`)
	}
	return C.CString(string(data))
}

//export GetActiveWindowInfo
func GetActiveWindowInfo() *C.char {
	title := robotgo.GetTitle()
	pid := int32(C.getActiveWindowPid())

	procName := ""
	if proc, err := psprocess.NewProcess(pid); err == nil {
		if name, err := proc.Name(); err == nil {
			procName = strings.TrimSuffix(name, ".exe")
		}
	}

	type payload struct {
		ProcessName string `json:"processName"`
		WindowTitle string `json:"windowTitle"`
	}
	data, _ := json.Marshal(payload{ProcessName: procName, WindowTitle: title})
	return C.CString(string(data))
}

func main() {}
