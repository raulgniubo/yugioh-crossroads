//go:build windows

// Package wintun is a stand-in for golang.zx2c4.com/wintun, built for Crossroads' network helper.
// The helper runs Tailscale in userspace (tsnet) and never makes a TUN device, so nothing here is
// ever called; it only lets wireguard-go's tun package compile. Every call says it is not there.
package wintun

import (
	"errors"

	"golang.org/x/sys/windows"
)

var errNo = errors.New("wintun is not part of this program")

type Adapter struct{}

type Packet []byte

type Session struct{}

func CreateAdapter(name, tunnelType string, requestedGUID *windows.GUID) (*Adapter, error) {
	return nil, errNo
}

func OpenAdapter(name string) (*Adapter, error) { return nil, errNo }

func RunningVersion() (uint32, error) { return 0, errNo }

func (a *Adapter) Close() error { return nil }

func (a *Adapter) LUID() uint64 { return 0 }

func (a *Adapter) StartSession(capacity uint32) (Session, error) { return Session{}, errNo }

func (s Session) End() {}

func (s Session) ReadWaitEvent() windows.Handle { return 0 }

func (s Session) ReceivePacket() ([]byte, error) { return nil, errNo }

func (s Session) ReleaseReceivePacket(packet []byte) {}

func (s Session) AllocateSendPacket(packetSize int) ([]byte, error) { return nil, errNo }

func (s Session) SendPacket(packet []byte) {}
