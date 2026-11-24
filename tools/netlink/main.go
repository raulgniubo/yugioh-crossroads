// Crossroads Link: Tailscale inside the game, for online duels (0.73.0).
//
// The game starts this small program for the Duel Group it is in. It joins that group's private
// network (a Tailscale tailnet that only holds copies of the game) with Tailscale's own library
// (tsnet: nothing is installed, nothing else on the computer is touched) and then only does three
// things, all on 127.0.0.1 and only for whoever knows the token the game gave it:
//
//   - a control port (HTTP): /status (who is in the group and online), /ping (how far a member
//     is, and whether the path is direct), /quit
//   - a dial port: the game connects, says "DIAL <token> <member ip>" and the connection is then
//     joined to that member's game
//   - duels coming in from members (tailnet port 41213) are handed to the game's own port, after
//     a first line "FROM <ip> <hostname>"
//
// It registers as an ephemeral node (the group forgets it shortly after it goes away) and keeps
// nothing on disk but its log. It quits by itself when the game stops asking for its status.
package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/netip"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"tailscale.com/ipn/store/mem"
	"tailscale.com/tailcfg"
	"tailscale.com/tsnet"
)

const duelPort = 41213

var (
	flagDir      = flag.String("dir", "", "folder for the log")
	flagCtl      = flag.Int("ctl", 0, "control port on 127.0.0.1")
	flagDial     = flag.Int("dial", 0, "dial port on 127.0.0.1")
	flagGame     = flag.Int("game", 0, "the game's own port on 127.0.0.1 (duels coming in)")
	flagHost     = flag.String("hostname", "xroads", "this copy's name in the group")
	flagToken    = flag.String("token", "", "the secret the game uses to talk to this program")
	flagKeyFile  = flag.String("keyfile", "", "a file holding the group's key (read, then deleted)")
	flagIdle     = flag.Int("idle", 25, "quit after this many seconds without a status request")
	flagControl  = flag.String("control", "", "coordination server (default: Tailscale's)")
	flagSelfTest = flag.Bool("selftest", false, "start, print the build, quit")
)

var (
	srv      *tsnet.Server
	lastPoll atomic.Int64
	logMu    sync.Mutex
	logFile  *os.File
	startErr atomic.Value // string
	started  atomic.Bool
)

func logf(format string, a ...any) {
	logMu.Lock()
	defer logMu.Unlock()
	if logFile == nil {
		return
	}
	// (a log that never outgrows 2 MB: it starts over)
	if fi, err := logFile.Stat(); err == nil && fi.Size() > 2<<20 {
		logFile.Truncate(0)
		logFile.Seek(0, 0)
	}
	fmt.Fprintf(logFile, time.Now().Format("2006-01-02 15:04:05 ")+format+"\n", a...)
}

func main() {
	flag.Parse()
	if *flagSelfTest {
		fmt.Println("crossroads-link ok")
		return
	}
	if *flagToken == "" || *flagCtl == 0 || *flagDial == 0 || *flagGame == 0 {
		fmt.Fprintln(os.Stderr, "missing -token, -ctl, -dial or -game")
		os.Exit(2)
	}
	// Nothing about this program is sent to Tailscale's log service.
	os.Setenv("TS_NO_LOGS_NO_SUPPORT", "true")
	if *flagDir != "" {
		os.MkdirAll(*flagDir, 0700)
		f, err := os.OpenFile(filepath.Join(*flagDir, "link.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0600)
		if err == nil {
			logFile = f
		}
	}
	key := ""
	if *flagKeyFile != "" {
		if b, err := os.ReadFile(*flagKeyFile); err == nil {
			key = strings.TrimSpace(string(b))
		}
		os.Remove(*flagKeyFile)
	}
	logf("start %s (game port %d)", *flagHost, *flagGame)
	lastPoll.Store(time.Now().Unix())
	startErr.Store("")
	dir := *flagDir
	if dir == "" {
		dir, _ = os.MkdirTemp("", "xroads")
	}
	srv = &tsnet.Server{
		Dir:        filepath.Join(dir, "ts"),
		Hostname:   *flagHost,
		AuthKey:    key,
		Ephemeral:  true,
		Store:      new(mem.Store),
		ControlURL: *flagControl,
		Logf:       func(format string, a ...any) { logf("ts: "+format, a...) },
	}
	go serveControl()
	go serveDial()
	go watchIdle()
	if key == "" {
		startErr.Store("no key")
	} else {
		go func() {
			if err := srv.Start(); err != nil {
				logf("start failed: %v", err)
				startErr.Store(err.Error())
				return
			}
			started.Store(true)
			ln, err := srv.Listen("tcp", fmt.Sprintf(":%d", duelPort))
			if err != nil {
				logf("listen failed: %v", err)
				startErr.Store(err.Error())
				return
			}
			for {
				c, err := ln.Accept()
				if err != nil {
					logf("accept: %v", err)
					return
				}
				go incoming(c)
			}
		}()
	}
	select {}
}

// A member's game is calling: it is joined to this game's own port.
func incoming(c net.Conn) {
	defer c.Close()
	g, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", *flagGame), 5*time.Second)
	if err != nil {
		logf("the game is not listening: %v", err)
		return
	}
	defer g.Close()
	from := c.RemoteAddr().String()
	host := ""
	if ap, err := netip.ParseAddrPort(from); err == nil {
		from = ap.Addr().String()
		if lc, err := srv.LocalClient(); err == nil {
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			if who, err := lc.WhoIs(ctx, ap.String()); err == nil && who.Node != nil {
				host = who.Node.Hostinfo.Hostname()
			}
			cancel()
		}
	}
	fmt.Fprintf(g, "FROM %s %s\n", from, host)
	pipe(c, g)
}

func pipe(a, b net.Conn) {
	done := make(chan struct{}, 2)
	go func() { io.Copy(a, b); done <- struct{}{} }()
	go func() { io.Copy(b, a); done <- struct{}{} }()
	<-done
}

// The game wants to talk to a member: "DIAL <token> <ip>\n", then the connection is theirs.
func serveDial() {
	ln, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", *flagDial))
	if err != nil {
		logf("dial port: %v", err)
		os.Exit(3)
	}
	for {
		c, err := ln.Accept()
		if err != nil {
			continue
		}
		go func(c net.Conn) {
			defer c.Close()
			c.SetReadDeadline(time.Now().Add(10 * time.Second))
			line, err := bufio.NewReader(c).ReadString('\n')
			if err != nil {
				return
			}
			f := strings.Fields(line)
			if len(f) != 3 || f[0] != "DIAL" || f[1] != *flagToken {
				fmt.Fprintf(c, "ERR bad request\n")
				return
			}
			c.SetReadDeadline(time.Time{})
			if !started.Load() {
				fmt.Fprintf(c, "ERR not connected to the group\n")
				return
			}
			ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
			m, err := srv.Dial(ctx, "tcp", fmt.Sprintf("%s:%d", f[2], duelPort))
			cancel()
			if err != nil {
				logf("dial %s: %v", f[2], err)
				fmt.Fprintf(c, "ERR %s\n", strings.ReplaceAll(err.Error(), "\n", " "))
				return
			}
			defer m.Close()
			fmt.Fprintf(c, "OK\n")
			pipe(c, m)
		}(c)
	}
}

func watchIdle() {
	for {
		time.Sleep(2 * time.Second)
		if time.Now().Unix()-lastPoll.Load() > int64(*flagIdle) {
			logf("the game stopped asking: quitting")
			quit()
		}
	}
}

func quit() {
	if srv != nil && started.Load() {
		srv.Close()
	}
	os.Exit(0)
}

type peerOut struct {
	IP       string `json:"ip"`
	Host     string `json:"host"`
	DNS      string `json:"dns"`
	OS       string `json:"os"`
	Online   bool   `json:"online"`
	LastSeen int64  `json:"last_seen"`
	Direct   bool   `json:"direct"`
	Relay    string `json:"relay"`
}

func serveControl() {
	mux := http.NewServeMux()
	auth := func(h http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			if r.Header.Get("X-Token") != *flagToken {
				http.Error(w, "no", http.StatusForbidden)
				return
			}
			lastPoll.Store(time.Now().Unix())
			w.Header().Set("Content-Type", "application/json")
			h(w, r)
		}
	}
	mux.HandleFunc("/status", auth(func(w http.ResponseWriter, r *http.Request) {
		out := map[string]any{"state": "Starting", "error": startErr.Load().(string), "peers": []peerOut{}}
		if !started.Load() {
			if out["error"] != "" {
				out["state"] = "Error"
			}
			json.NewEncoder(w).Encode(out)
			return
		}
		lc, err := srv.LocalClient()
		if err != nil {
			out["state"] = "Error"
			out["error"] = err.Error()
			json.NewEncoder(w).Encode(out)
			return
		}
		ctx, cancel := context.WithTimeout(r.Context(), 4*time.Second)
		defer cancel()
		st, err := lc.Status(ctx)
		if err != nil {
			out["error"] = err.Error()
			json.NewEncoder(w).Encode(out)
			return
		}
		out["state"] = st.BackendState
		out["auth_url"] = st.AuthURL
		out["health"] = st.Health
		if st.CurrentTailnet != nil {
			out["tailnet"] = st.CurrentTailnet.Name
		}
		if st.Self != nil {
			ip := ""
			if len(st.Self.TailscaleIPs) > 0 {
				ip = st.Self.TailscaleIPs[0].String()
			}
			out["self"] = map[string]any{"ip": ip, "host": st.Self.HostName, "dns": st.Self.DNSName, "online": st.Self.Online,
				"relay": st.Self.Relay, "addrs": len(st.Self.Addrs)}
		}
		peers := []peerOut{}
		for _, p := range st.Peer {
			if len(p.TailscaleIPs) == 0 {
				continue
			}
			po := peerOut{IP: p.TailscaleIPs[0].String(), Host: p.HostName, DNS: p.DNSName, OS: p.OS, Online: p.Online,
				Direct: p.CurAddr != "", Relay: p.Relay}
			if !p.LastSeen.IsZero() {
				po.LastSeen = p.LastSeen.Unix()
			}
			peers = append(peers, po)
		}
		sort.Slice(peers, func(i, j int) bool { return peers[i].Host < peers[j].Host })
		out["peers"] = peers
		json.NewEncoder(w).Encode(out)
	}))
	mux.HandleFunc("/ping", auth(func(w http.ResponseWriter, r *http.Request) {
		ip, err := netip.ParseAddr(r.URL.Query().Get("ip"))
		if err != nil || !started.Load() {
			json.NewEncoder(w).Encode(map[string]any{"error": "no such member"})
			return
		}
		lc, err := srv.LocalClient()
		if err != nil {
			json.NewEncoder(w).Encode(map[string]any{"error": err.Error()})
			return
		}
		ctx, cancel := context.WithTimeout(r.Context(), 6*time.Second)
		defer cancel()
		res, err := lc.Ping(ctx, ip, tailcfg.PingDisco)
		if err != nil {
			json.NewEncoder(w).Encode(map[string]any{"error": err.Error()})
			return
		}
		json.NewEncoder(w).Encode(map[string]any{"ms": res.LatencySeconds * 1000, "direct": res.Endpoint != "", "endpoint": res.Endpoint,
			"derp": res.DERPRegionCode, "error": res.Err})
	}))
	mux.HandleFunc("/quit", auth(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("{}"))
		go func() { time.Sleep(100 * time.Millisecond); quit() }()
	}))
	s := &http.Server{Addr: fmt.Sprintf("127.0.0.1:%d", *flagCtl), Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	if err := s.ListenAndServe(); err != nil {
		log.Printf("control port: %v", err)
		os.Exit(3)
	}
}
