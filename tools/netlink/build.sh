#!/bin/bash
# Builds Crossroads Link (tools/netlink/main.go) for macOS (arm64 + x86_64), Windows and Linux into netbin/.
# Tailscale's source is fetched with git (the Go module proxy may not be reachable): the module paths that
# live on their own domains are pointed at their GitHub mirrors, and golang.zx2c4.com/wintun (a Windows TUN
# driver this program never uses) at a stand-in (tools/netlink/wintunstub).
#   tools/netlink/build.sh            (needs Go 1.24.4 or newer and git)
set -e
cd "$(dirname "$0")"
HERE=$(pwd)
TS=v1.86.5
WORK=${NETLINK_WORK:-/tmp/xroads-netlink}
if [ ! -d $WORK/ts ]; then
	mkdir -p $WORK
	git clone -q --depth 1 --branch $TS https://github.com/tailscale/tailscale $WORK/ts
	cd $WORK/ts
	cp go.mod go.mod.orig
	python3 - <<'P'
import re
s=open('go.mod').read()
reqs=dict(re.findall(r'^\s+(\S+) (v\S+)', s, re.M))
m={'go4.org/mem':'github.com/go4org/mem','go4.org/netipx':'github.com/go4org/netipx','filippo.io/edwards25519':'github.com/FiloSottile/edwards25519',
   'gvisor.dev/gvisor':'github.com/google/gvisor','golang.zx2c4.com/wireguard/windows':'github.com/WireGuard/wireguard-windows'}
for k in list(reqs):
    if k.startswith('golang.org/x/') and k.count('/')==2:
        m[k]='github.com/golang/'+k.split('/')[2]
lines=['replace %s => %s %s'%(k,v,reqs[k]) for k,v in m.items() if k in reqs]
lines.append('replace golang.zx2c4.com/wintun => ./third_party/wintunstub')
open('go.mod','w').write(s+'\n'+'\n'.join(lines)+'\n')
P
	mkdir -p third_party
	cp -r $HERE/wintunstub third_party/
fi
mkdir -p $WORK/ts/cmd/crossroads-link
cp $HERE/main.go $WORK/ts/cmd/crossroads-link/main.go
cd $WORK/ts
export GOPROXY=direct GOSUMDB=off GOFLAGS=-mod=mod GOTOOLCHAIN=local CGO_ENABLED=0
OUT=$HERE/../../netbin
mkdir -p $OUT
GOOS=darwin GOARCH=arm64 go build -trimpath -ldflags "-s -w" -o $OUT/crossroads-link-darwin-arm64.bin ./cmd/crossroads-link
GOOS=darwin GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o $OUT/crossroads-link-darwin-amd64.bin ./cmd/crossroads-link
GOOS=windows GOARCH=amd64 go build -trimpath -ldflags "-s -w -H windowsgui" -o $OUT/crossroads-link-windows-amd64.bin ./cmd/crossroads-link
GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o $OUT/crossroads-link-linux-amd64.bin ./cmd/crossroads-link
ls -la $OUT
