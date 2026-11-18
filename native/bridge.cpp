// Crossroads engine bridge: ocgcore behind one Godot method.
//   OcgBridge.op(code: int, data: PackedByteArray, size: int) -> PackedByteArray
// Everything in and out is little-endian bytes. Structured results come back in Godot's
// own binary Variant format, so GDScript reads them with bytes_to_var().
#include "gdextension_interface.h"
#include "ocgcore/ocgapi.h"
#include <lua.h>
#include <lauxlib.h>
#include <cstring>
#include <cstdlib>
#include <cstdint>
#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>
#include <memory>
#include <chrono>
#include <thread>
#include <algorithm>
#include <cmath>
#include <map>
#include <set>

// ---------------------------------------------------------------- a tiny value tree
struct JV {
	enum T { NIL, INT, STR, ARR, OBJ } t = NIL;
	int64_t i = 0;
	std::string s;
	std::vector<JV> a;
	std::vector<std::pair<std::string, JV>> o;
	JV() {}
	JV(int64_t v) : t(INT), i(v) {}
	JV(int v) : t(INT), i(v) {}
	JV(uint32_t v) : t(INT), i(v) {}
	JV(uint64_t v) : t(INT), i((int64_t)v) {}
	JV(const std::string& v) : t(STR), s(v) {}
	JV(const char* v) : t(STR), s(v) {}
	static JV arr() { JV v; v.t = ARR; return v; }
	static JV obj() { JV v; v.t = OBJ; return v; }
	JV& set(const char* k, JV v) { o.emplace_back(k, std::move(v)); return *this; }
	JV& push(JV v) { a.push_back(std::move(v)); return *this; }
	const JV* get(const char* k) const { for(auto& p : o) if(p.first == k) return &p.second; return nullptr; }
	int64_t geti(const char* k, int64_t d = 0) const { auto* v = get(k); return v ? v->i : d; }
};

static void put32(std::vector<uint8_t>& b, uint32_t v) { for(int k = 0; k < 4; ++k) b.push_back((v >> (8 * k)) & 0xff); }
static void put64(std::vector<uint8_t>& b, uint64_t v) { for(int k = 0; k < 8; ++k) b.push_back((v >> (8 * k)) & 0xff); }
static void putstr(std::vector<uint8_t>& b, const std::string& s) {
	put32(b, 4); put32(b, (uint32_t)s.size());
	b.insert(b.end(), s.begin(), s.end());
	while(b.size() % 4) b.push_back(0);
}
// Godot binary Variant: NIL 0, INT 2 (flag 1<<16 = 64 bit), STRING 4, DICTIONARY 27, ARRAY 28.
static void encode(std::vector<uint8_t>& b, const JV& v) {
	switch(v.t) {
	case JV::NIL: put32(b, 0); break;
	case JV::INT:
		if(v.i >= INT32_MIN && v.i <= INT32_MAX) { put32(b, 2); put32(b, (uint32_t)(int32_t)v.i); }
		else { put32(b, 2 | (1 << 16)); put64(b, (uint64_t)v.i); }
		break;
	case JV::STR: putstr(b, v.s); break;
	case JV::ARR: put32(b, 28); put32(b, (uint32_t)v.a.size()); for(auto& x : v.a) encode(b, x); break;
	case JV::OBJ: put32(b, 27); put32(b, (uint32_t)v.o.size()); for(auto& p : v.o) { putstr(b, p.first); encode(b, p.second); } break;
	}
}

// ---------------------------------------------------------------- byte reader
struct R {
	const uint8_t* p; size_t n; size_t pos = 0; bool bad = false;
	R(const uint8_t* p_, size_t n_) : p(p_), n(n_) {}
	template<typename T> T get() {
		T v{};
		if(pos + sizeof(T) > n) { bad = true; pos = n; return v; }
		std::memcpy(&v, p + pos, sizeof(T)); pos += sizeof(T); return v;
	}
	uint8_t u8() { return get<uint8_t>(); }
	uint16_t u16() { return get<uint16_t>(); }
	uint32_t u32() { return get<uint32_t>(); }
	int32_t i32() { return get<int32_t>(); }
	uint64_t u64() { return get<uint64_t>(); }
	size_t left() const { return n - pos; }
};

// ---------------------------------------------------------------- card data and scripts
struct CardRow { uint32_t code, alias, type, level, attribute; uint64_t race; int32_t atk, def; uint32_t lscale, rscale, link; std::vector<uint16_t> sets; };
static std::unordered_map<uint32_t, CardRow> g_cards;
static std::unordered_map<std::string, std::string> g_scripts;
// The same scripts already compiled. A duel loads about a megabyte of script when it starts, and
// the opponent starts hundreds of duels to think: compiled once, each start is several times faster.
static std::unordered_map<std::string, std::string> g_compiled;
static int dump_writer(lua_State*, const void* p, size_t sz, void* ud) { static_cast<std::string*>(ud)->append((const char*)p, sz); return 0; }
static void compile_scripts() {
	lua_State* L = luaL_newstate();
	if(!L) return;
	for(auto& kv : g_scripts) {
		if(g_compiled.count(kv.first)) continue;
		if(luaL_loadbuffer(L, kv.second.data(), kv.second.size(), kv.first.c_str()) == LUA_OK) {
			std::string out;
			if(lua_dump(L, dump_writer, &out, 0) == 0) g_compiled[kv.first] = std::move(out);
		}
		lua_settop(L, 0);
	}
	lua_close(L);
}
static std::mutex g_mutex;

static void card_reader(void*, uint32_t code, OCG_CardData* d) {
	static uint16_t none[1] = { 0 };
	std::memset(d, 0, sizeof(*d));
	d->code = code; d->setcodes = none;
	auto it = g_cards.find(code);
	if(it == g_cards.end()) return;
	const CardRow& c = it->second;
	d->alias = c.alias; d->type = c.type; d->level = c.level; d->attribute = c.attribute; d->race = c.race;
	d->attack = c.atk; d->defense = c.def; d->lscale = c.lscale; d->rscale = c.rscale; d->link_marker = c.link;
	d->setcodes = const_cast<uint16_t*>(c.sets.data());
}
static void card_reader_done(void*, OCG_CardData*) {}

// Everything needed to play a duel again from its first card: how it began and every answer given.
struct History {
	OCG_DuelOptions opt{};
	std::vector<OCG_NewCardInfo> cards;
	std::vector<std::vector<uint8_t>> answers;
	std::vector<std::pair<std::string, std::string>> scripts;
};

struct AiJob;
struct PMemo;
struct Duel { OCG_Duel d = nullptr; std::vector<std::string> logs; std::vector<std::string> missing; History hist; std::shared_ptr<AiJob> job; std::shared_ptr<PMemo> memo; };
static int script_reader(void* payload, OCG_Duel duel, const char* name) {
	auto it = g_scripts.find(name);
	if(it == g_scripts.end()) {
		// A card with no effect has no script, and the library asks for an optional file: neither is a fault.
		bool real = true;
		std::string n(name);
		if(n == "proc_unofficial.lua") real = false;
		if(n.size() > 5 && n[0] == 'c' && n[1] >= '0' && n[1] <= '9') {
			uint32_t code = (uint32_t)std::strtoul(n.c_str() + 1, nullptr, 10);
			auto ci = g_cards.find(code);
			if(code == 0 || (ci != g_cards.end() && (ci->second.type & 0x1) && !(ci->second.type & 0x20))) real = false;
		}
		if(payload && real) static_cast<Duel*>(payload)->missing.push_back(name);
		return 0;
	}
	auto bc = g_compiled.find(name);
	if(bc != g_compiled.end()) return OCG_LoadScript(duel, bc->second.data(), (uint32_t)bc->second.size(), name);
	return OCG_LoadScript(duel, it->second.data(), (uint32_t)it->second.size(), name);
}
static void log_handler(void* payload, const char* str, int type) {
	if(payload && str) {
		auto* d = static_cast<Duel*>(payload);
		if(d->logs.size() < 200) d->logs.push_back(std::to_string(type) + ":" + str);
	}
}
static std::unordered_map<uint32_t, std::unique_ptr<Duel>> g_duels;
static uint32_t g_next = 1;
static Duel* find_duel(uint32_t h) { auto it = g_duels.find(h); return it == g_duels.end() ? nullptr : it->second.get(); }

// ---------------------------------------------------------------- message parsing
static JV loc(R& r) { JV o = JV::obj(); o.set("con", r.u8()); o.set("loc", r.u8()); o.set("seq", r.u32()); o.set("pos", r.u32()); return o; }
static JV cardloc(R& r) { uint32_t code = r.u32(); JV o = loc(r); o.set("code", code); return o; }
static JV chain_entry(R& r, bool full_loc) {
	JV o = JV::obj();
	uint32_t code = r.u32();
	if(full_loc) { o = loc(r); } else { o.set("con", r.u8()); o.set("loc", r.u8()); o.set("seq", r.u32()); }
	o.set("code", code); o.set("desc", r.u64()); o.set("mode", r.u8());
	return o;
}
static JV card4(R& r) { JV o = JV::obj(); o.set("code", r.u32()); o.set("con", r.u8()); o.set("loc", r.u8()); o.set("seq", r.u32()); return o; }
static JV card1(R& r) { JV o = JV::obj(); o.set("code", r.u32()); o.set("con", r.u8()); o.set("loc", r.u8()); o.set("seq", r.u8()); return o; }

static JV parse_msg(const uint8_t* p, size_t n) {
	R r(p, n);
	int t = r.u8();
	JV m = JV::obj();
	m.set("t", t);
	auto list = [&](const char* key, JV (*fn)(R&)) { uint32_t c = r.u32(); JV a = JV::arr(); for(uint32_t i = 0; i < c && !r.bad; ++i) a.push(fn(r)); m.set(key, std::move(a)); };
	auto chains = [&](bool full) { uint32_t c = r.u32(); JV a = JV::arr(); for(uint32_t i = 0; i < c && !r.bad; ++i) a.push(chain_entry(r, full)); m.set("chains", std::move(a)); };
	switch(t) {
	case 1: break;
	case 2: m.set("ht", r.u8()); m.set("p", r.u8()); m.set("v", r.u64()); break;
	case 5: m.set("p", r.u8()); m.set("reason", r.u8()); break;
	case 10: {
		m.set("p", r.u8()); chains(false);
		uint32_t c = r.u32(); JV a = JV::arr();
		for(uint32_t i = 0; i < c && !r.bad; ++i) { JV o = card1(r); o.set("direct", r.u8()); a.push(std::move(o)); }
		m.set("attacks", std::move(a)); m.set("to_m2", r.u8()); m.set("to_ep", r.u8());
		break; }
	case 11:
		m.set("p", r.u8()); list("summon", card4); list("spsummon", card4); list("repos", card1); list("mset", card4); list("sset", card4);
		chains(false); m.set("to_bp", r.u8()); m.set("to_ep", r.u8()); m.set("shuffle", r.u8());
		break;
	case 12: { m.set("p", r.u8()); JV c = cardloc(r); m.set("card", std::move(c)); m.set("desc", r.u64()); break; }
	case 13: m.set("p", r.u8()); m.set("desc", r.u64()); break;
	case 14: case 143: case 142: {
		m.set("p", r.u8()); int c = r.u8(); JV a = JV::arr();
		for(int i = 0; i < c && !r.bad; ++i) a.push(r.u64());
		m.set("opts", std::move(a)); break; }
	case 15: m.set("p", r.u8()); m.set("cancel", r.u8()); m.set("min", r.u32()); m.set("max", r.u32()); list("cards", cardloc); break;
	case 16: m.set("p", r.u8()); m.set("spe", r.u8()); m.set("forced", r.u8()); m.set("hint0", r.u32()); m.set("hint1", r.u32()); chains(true); break;
	case 18: case 24: m.set("p", r.u8()); m.set("count", r.u8()); m.set("flag", r.u32()); break;
	case 19: m.set("p", r.u8()); m.set("code", r.u32()); m.set("positions", r.u8()); break;
	case 20: {
		m.set("p", r.u8()); m.set("cancel", r.u8()); m.set("min", r.u32()); m.set("max", r.u32());
		uint32_t c = r.u32(); JV a = JV::arr();
		for(uint32_t i = 0; i < c && !r.bad; ++i) { JV o = card4(r); o.set("param", r.u8()); a.push(std::move(o)); }
		m.set("cards", std::move(a)); break; }
	case 21: case 25: {
		m.set("p", r.u8()); uint32_t c = r.u32(); JV a = JV::arr();
		for(uint32_t i = 0; i < c && !r.bad; ++i) { JV o = JV::obj(); o.set("code", r.u32()); o.set("con", r.u8()); o.set("loc", r.u32()); o.set("seq", r.u32()); a.push(std::move(o)); }
		m.set("cards", std::move(a)); break; }
	case 22: {
		m.set("p", r.u8()); m.set("ctype", r.u16()); m.set("count", r.u16());
		uint32_t c = r.u32(); JV a = JV::arr();
		for(uint32_t i = 0; i < c && !r.bad; ++i) { JV o = card1(r); o.set("n", r.u16()); a.push(std::move(o)); }
		m.set("cards", std::move(a)); break; }
	case 23: {
		m.set("p", r.u8()); m.set("mode", r.u8()); m.set("acc", r.u32()); m.set("min", r.u32()); m.set("max", r.u32());
		for(int k = 0; k < 2; ++k) {
			uint32_t c = r.u32(); JV a = JV::arr();
			for(uint32_t i = 0; i < c && !r.bad; ++i) { JV o = cardloc(r); o.set("param", r.u32()); a.push(std::move(o)); }
			m.set(k == 0 ? "must" : "cards", std::move(a));
		}
		break; }
	case 26: m.set("p", r.u8()); m.set("finish", r.u8()); m.set("cancel", r.u8()); m.set("min", r.u32()); m.set("max", r.u32()); list("cards", cardloc); list("unsel", cardloc); break;
	case 30: case 42: case 31: m.set("p", r.u8()); list("cards", card4); break;
	case 32: m.set("p", r.u8()); break;
	case 33: case 39: { m.set("p", r.u8()); uint32_t c = r.u32(); JV a = JV::arr(); for(uint32_t i = 0; i < c && !r.bad; ++i) a.push(r.u32()); m.set("codes", std::move(a)); break; }
	case 36: {
		m.set("loc", r.u8()); int c = r.u8(); JV a = JV::arr(), b = JV::arr();
		for(int i = 0; i < c && !r.bad; ++i) a.push(loc(r));
		for(int i = 0; i < c && !r.bad; ++i) b.push(loc(r));
		m.set("from", std::move(a)); m.set("to", std::move(b)); break; }
	case 38: m.set("p", r.u8()); m.set("seq", r.u32()); m.set("code", r.u32()); m.set("pos", r.u32()); break;
	case 40: m.set("p", r.u8()); break;
	case 41: m.set("phase", r.u16()); break;
	case 50: { uint32_t code = r.u32(); m.set("code", code); m.set("from", loc(r)); m.set("to", loc(r)); m.set("reason", r.u32()); break; }
	case 53: m.set("code", r.u32()); m.set("con", r.u8()); m.set("loc", r.u8()); m.set("seq", r.u8()); m.set("pp", r.u8()); m.set("cp", r.u8()); break;
	case 54: case 60: case 62: case 64: m.set("card", cardloc(r)); break;
	case 55: m.set("a", cardloc(r)); m.set("b", cardloc(r)); break;
	case 56: m.set("flag", r.u32()); break;
	case 70: { JV c = cardloc(r); m.set("card", std::move(c)); m.set("tc", r.u8()); m.set("tl", r.u8()); m.set("ts", r.u32()); m.set("desc", r.u64()); m.set("n", r.u32()); break; }
	case 71: case 72: case 73: case 75: case 76: m.set("n", r.u8()); break;
	case 80: case 83: case 190: list("cards", loc); break;
	case 81: m.set("p", r.u8()); list("cards", loc); break;
	case 90: {
		m.set("p", r.u8()); uint32_t c = r.u32(); JV a = JV::arr();
		for(uint32_t i = 0; i < c && !r.bad; ++i) { JV o = JV::obj(); o.set("code", r.u32()); o.set("pos", r.u32()); a.push(std::move(o)); }
		m.set("cards", std::move(a)); break; }
	case 91: case 92: case 94: case 100: m.set("p", r.u8()); m.set("v", r.u32()); break;
	case 93: case 96: case 97: m.set("a", loc(r)); m.set("b", loc(r)); break;
	case 95: m.set("a", loc(r)); break;
	case 101: case 102: m.set("ctype", r.u16()); m.set("con", r.u8()); m.set("loc", r.u8()); m.set("seq", r.u8()); m.set("n", r.u16()); break;
	case 110: m.set("a", loc(r)); m.set("b", loc(r)); break;
	case 111: {
		m.set("a", loc(r)); m.set("aa", r.i32()); m.set("ad", r.i32()); m.set("abd", r.u8());
		m.set("b", loc(r)); m.set("da", r.i32()); m.set("dd", r.i32()); m.set("dbd", r.u8()); break; }
	case 120: m.set("a", loc(r)); m.set("code", r.u32()); break;
	case 130: case 131: { m.set("p", r.u8()); int c = r.u8(); JV a = JV::arr(); for(int i = 0; i < c && !r.bad; ++i) a.push(r.u8()); m.set("res", std::move(a)); break; }
	case 132: m.set("p", r.u8()); break;
	case 133: m.set("res", r.u8()); break;
	case 140: m.set("p", r.u8()); m.set("count", r.u8()); m.set("avail", r.u64()); break;
	case 141: m.set("p", r.u8()); m.set("count", r.u8()); m.set("avail", r.u32()); break;
	case 160: m.set("a", loc(r)); m.set("ht", r.u8()); m.set("v", r.u64()); break;
	case 165: m.set("p", r.u8()); m.set("ht", r.u8()); m.set("v", r.u64()); break;
	case 170: m.set("code", r.u32()); break;
	default: m.set("raw", (int64_t)n); break;
	}
	if(r.bad) m.set("bad", 1);
	return m;
}

// ---------------------------------------------------------------- card queries
static const uint32_t QFLAGS = 0x1 | 0x2 | 0x4 | 0x8 | 0x10 | 0x20 | 0x40 | 0x80 | 0x100 | 0x200 | 0x400 | 0x800 | 0x1000 | 0x4000 | 0x10000 | 0x20000 | 0x40000 | 0x80000 | 0x100000;
static JV parse_query_list(const uint8_t* p, size_t n) {
	R r(p, n);
	JV out = JV::arr();
	while(r.left() >= 2 && !r.bad) {
		JV c = JV::obj();
		bool any = false;
		for(;;) {
			uint16_t size = r.u16();
			if(size == 0) break;                    // an empty zone
			any = true;
			uint32_t flag = r.u32();
			size_t end = r.pos + (size - 4);
			if(flag == 0x80000000u) break;
			switch(flag) {
			case 0x1: c.set("code", r.u32()); break;
			case 0x2: c.set("pos", r.u32()); break;
			case 0x4: c.set("alias", r.u32()); break;
			case 0x8: c.set("type", r.u32()); break;
			case 0x10: c.set("lvl", r.u32()); break;
			case 0x20: c.set("rank", r.u32()); break;
			case 0x40: c.set("attr", r.u32()); break;
			case 0x80: c.set("race", r.u64()); break;
			case 0x100: c.set("atk", r.i32()); break;
			case 0x200: c.set("def", r.i32()); break;
			case 0x400: c.set("batk", r.i32()); break;
			case 0x800: c.set("bdef", r.i32()); break;
			case 0x1000: c.set("reason", r.u32()); break;
			case 0x4000: { JV e = JV::obj(); e.set("con", r.u8()); e.set("loc", r.u8()); e.set("seq", r.u32()); e.set("pos", r.u32()); c.set("eq", std::move(e)); break; }
			case 0x10000: { uint32_t k = r.u32(); JV a = JV::arr(); for(uint32_t i = 0; i < k && !r.bad; ++i) a.push(r.u32()); c.set("ov", std::move(a)); break; }
			case 0x20000: { uint32_t k = r.u32(); JV a = JV::arr(); for(uint32_t i = 0; i < k && !r.bad; ++i) a.push(r.u32()); c.set("ctr", std::move(a)); break; }
			case 0x40000: c.set("owner", r.u8()); break;
			case 0x80000: c.set("status", r.u32()); break;
			case 0x100000: c.set("pub", r.u8()); break;
			default: break;
			}
			if(end <= r.n) r.pos = end; else { r.bad = true; break; }
		}
		if(any) out.push(std::move(c)); else out.push(JV());
	}
	return out;
}

#include "ai.hpp"

struct AiJob { std::mutex m; bool done = false; Decision d; PMemo memo[2]; };
static PMemo* memos_of(Duel* d) {
	if(!d->memo) d->memo = std::shared_ptr<PMemo>(new PMemo[2], std::default_delete<PMemo[]>());
	return d->memo.get();
}

// ---------------------------------------------------------------- operations
static std::vector<uint8_t> run_op(int code, const uint8_t* data, size_t size) {
	std::lock_guard<std::mutex> lock(g_mutex);
	std::vector<uint8_t> out;
	R r(data, size);
	switch(code) {
	case 0: { int a = 0, b = 0; OCG_GetVersion(&a, &b); put32(out, (uint32_t)a); put32(out, (uint32_t)b); break; }
	case 1: {   // card table
		uint32_t n = r.u32();
		for(uint32_t i = 0; i < n && !r.bad; ++i) {
			CardRow c{};
			c.code = r.u32(); c.alias = r.u32(); c.type = r.u32(); c.level = r.u32(); c.attribute = r.u32(); c.race = r.u64();
			c.atk = r.i32(); c.def = r.i32(); c.lscale = r.u32(); c.rscale = r.u32(); c.link = r.u32();
			int k = r.u8();
			for(int j = 0; j < k; ++j) c.sets.push_back(r.u16());
			c.sets.push_back(0);
			g_cards[c.code] = std::move(c);
		}
		put32(out, (uint32_t)g_cards.size());
		break; }
	case 2: {   // script archive
		uint32_t n = r.u32();
		for(uint32_t i = 0; i < n && !r.bad; ++i) {
			uint16_t nl = r.u16();
			if(r.left() < nl) break;
			std::string name((const char*)r.p + r.pos, nl); r.pos += nl;
			uint32_t dl = r.u32();
			if(r.left() < dl) break;
			g_scripts[name] = std::string((const char*)r.p + r.pos, dl); r.pos += dl;
		}
		compile_scripts();
		put32(out, (uint32_t)g_scripts.size());
		break; }
	case 10: {  // create a duel
		OCG_DuelOptions o{};
		for(int i = 0; i < 4; ++i) o.seed[i] = r.u64();
		o.flags = r.u64();
		o.team1.startingLP = r.u32(); o.team1.startingDrawCount = r.u32(); o.team1.drawCountPerTurn = r.u32();
		o.team2.startingLP = r.u32(); o.team2.startingDrawCount = r.u32(); o.team2.drawCountPerTurn = r.u32();
		auto d = std::make_unique<Duel>();
		o.cardReader = card_reader; o.scriptReader = script_reader; o.logHandler = log_handler; o.cardReaderDone = card_reader_done;
		o.payload2 = d.get(); o.payload3 = d.get();
		int st = OCG_CreateDuel(&d->d, &o);
		if(st != 0 || !d->d) { put32(out, 0); put32(out, (uint32_t)st); break; }
		d->hist.opt = o;
		for(const char* f : { "constant.lua", "utility.lua" }) script_reader(d.get(), d->d, f);
		uint32_t h = g_next++;
		g_duels[h] = std::move(d);
		put32(out, h); put32(out, 0);
		break; }
	case 11: {  // add cards: handle, count, then (team, duelist, code, con, loc, seq, pos)
		Duel* d = find_duel(r.u32());
		uint32_t n = r.u32();
		for(uint32_t i = 0; d && i < n && !r.bad; ++i) {
			OCG_NewCardInfo c{};
			c.team = r.u8(); c.duelist = r.u8(); c.code = r.u32(); c.con = r.u8(); c.loc = r.u32(); c.seq = r.u32(); c.pos = r.u32();
			OCG_DuelNewCard(d->d, &c);
			d->hist.cards.push_back(c);
		}
		break; }
	case 12: { Duel* d = find_duel(r.u32()); if(d) OCG_StartDuel(d->d); break; }
	case 13: {  // run until the duel waits for an answer or ends
		Duel* d = find_duel(r.u32());
		JV res = JV::obj();
		JV msgs = JV::arr();
		int status = 0;
		if(d) {
			for(int guard = 0; guard < 20000; ++guard) {
				status = OCG_DuelProcess(d->d);
				uint32_t len = 0;
				auto* buf = (const uint8_t*)OCG_DuelGetMessage(d->d, &len);
				size_t pos = 0;
				while(buf && pos + 4 <= len) {
					uint32_t l; std::memcpy(&l, buf + pos, 4); pos += 4;
					if(pos + l > len) break;
					if(l > 0) msgs.push(parse_msg(buf + pos, l));
					pos += l;
				}
				if(status != OCG_DUEL_STATUS_CONTINUE) break;
			}
		}
		res.set("status", status);
		res.set("msgs", std::move(msgs));
		encode(out, res);
		break; }
	case 14: {
		Duel* d = find_duel(r.u32());
		if(d) {
			OCG_DuelSetResponse(d->d, r.p + r.pos, (uint32_t)r.left());
			d->hist.answers.emplace_back(r.p + r.pos, r.p + r.pos + r.left());
		}
		break; }
	case 15: {  // query: handle, location mask. Returns [player][location] lists.
		Duel* d = find_duel(r.u32());
		uint32_t mask = r.u32();
		JV res = JV::arr();
		for(int p = 0; d && p < 2; ++p) {
			JV pl = JV::obj();
			for(uint32_t l = 1; l <= 0x40; l <<= 1) {
				if(!(mask & l)) continue;
				OCG_QueryInfo q{}; q.flags = QFLAGS; q.con = (uint8_t)p; q.loc = l;
				uint32_t len = 0;
				auto* buf = (const uint8_t*)OCG_DuelQueryLocation(d->d, &len, &q);
				pl.set(std::to_string(l).c_str(), (buf && len >= 4) ? parse_query_list(buf + 4, len - 4) : JV::arr());
			}
			res.push(std::move(pl));
		}
		encode(out, res);
		break; }
	case 16: { g_duels.erase(r.u32()); break; }
	case 17: {  // logs and missing scripts since the last call
		Duel* d = find_duel(r.u32());
		JV res = JV::obj();
		JV a = JV::arr(), b = JV::arr();
		if(d) { for(auto& s : d->logs) a.push(s); for(auto& s : d->missing) b.push(s); d->logs.clear(); d->missing.clear(); }
		res.set("logs", std::move(a)); res.set("missing", std::move(b));
		encode(out, res);
		break; }
	case 18: {  // life points and counts
		Duel* d = find_duel(r.u32());
		JV res = JV::arr();
		if(d) {
			uint32_t len = 0;
			auto* buf = (const uint8_t*)OCG_DuelQueryField(d->d, &len);
			R q(buf, buf ? len : 0);
			q.u32();
			for(int p = 0; p < 2; ++p) {
				JV pl = JV::obj();
				pl.set("lp", q.u32());
				for(int z = 0; z < 7 + 8; ++z) { if(q.u8()) { q.u8(); q.u32(); } }
				pl.set("deck", q.u32()); pl.set("hand", q.u32()); pl.set("gy", q.u32()); pl.set("banished", q.u32()); pl.set("extra", q.u32()); q.u32();
				res.push(std::move(pl));
			}
		}
		encode(out, res);
		break; }
	case 19: {  // load one more script into a duel: handle, name length (u16), name, text
		Duel* d = find_duel(r.u32());
		uint16_t nl = r.u16();
		if(!d || r.left() < nl) break;
		std::string name((const char*)r.p + r.pos, nl); r.pos += nl;
		put32(out, (uint32_t)OCG_LoadScript(d->d, (const char*)r.p + r.pos, (uint32_t)r.left(), name.c_str()));
		d->hist.scripts.emplace_back(name, std::string((const char*)r.p + r.pos, r.left()));
		break; }
	case 30: case 31: {  // the opponent thinks: handle, level, time (ms), seed. 30 waits for the answer, 31 thinks in the background.
		Duel* d = find_duel(r.u32());
		int level = (int)r.u32(); int ms = (int)r.u32(); uint64_t seed = r.u64();
		if(!d) break;
		if(code == 30) {
			Decision dec = decide(d->hist, level, ms, seed, memos_of(d));
			put32(out, (uint32_t)dec.sims); put32(out, (uint32_t)dec.cands); put32(out, (uint32_t)dec.ms);
			out.insert(out.end(), dec.bytes.begin(), dec.bytes.end());
			d->logs.push_back("9:" + dec.notes);
		} else {
			auto job = std::make_shared<AiJob>();
			d->job = job;
			History copy = d->hist;
			PMemo* mem = memos_of(d);
			job->memo[0] = mem[0]; job->memo[1] = mem[1];
			std::thread([job, copy, level, ms, seed]() {
				Decision dec = decide(copy, level, ms, seed, job->memo);
				std::lock_guard<std::mutex> l(job->m);
				job->d = std::move(dec);
				job->done = true;
			}).detach();
		}
		break; }
	case 32: {  // is the answer ready? 0 nothing asked, 1 thinking, 2 ready (then: tries, answers weighed, ms, the answer)
		Duel* d = find_duel(r.u32());
		if(!d || !d->job) { out.push_back(0); break; }
		std::lock_guard<std::mutex> l(d->job->m);
		if(!d->job->done) { out.push_back(1); break; }
		{ PMemo* mem = memos_of(d); mem[0] = d->job->memo[0]; mem[1] = d->job->memo[1]; }
		out.push_back(2);
		put32(out, (uint32_t)d->job->d.sims); put32(out, (uint32_t)d->job->d.cands); put32(out, (uint32_t)d->job->d.ms);
		out.insert(out.end(), d->job->d.bytes.begin(), d->job->d.bytes.end());
		break; }
	case 35: {  // a set position played on from there (test boards): explicit cards, then who thinks how
		History h{};
		for(int i = 0; i < 4; ++i) h.opt.seed[i] = r.u64();
		h.opt.flags = r.u64();
		h.opt.team1.startingLP = r.u32(); h.opt.team2.startingLP = r.u32();
		h.opt.team1.drawCountPerTurn = 1; h.opt.team2.drawCountPerTurn = 1;
		int level0 = (int)r.u32(), level1 = (int)r.u32(), ms = (int)r.u32(), max_turns = (int)r.u32();
		uint64_t seed = r.u64();
		uint32_t n = r.u32();
		for(uint32_t i = 0; i < n && !r.bad; ++i) {
			OCG_NewCardInfo ci{};
			ci.team = r.u8(); ci.code = r.u32(); ci.con = ci.team; ci.loc = r.u32(); ci.seq = r.u32(); ci.pos = r.u32();
			h.cards.push_back(ci);
		}
		MatchResult mr = play_match(h, level0, level1, seed, ms, max_turns);
		JV res = JV::obj();
		res.set("winner", mr.winner); res.set("turns", mr.turns); res.set("sims", (int64_t)mr.sims); res.set("refused", mr.refused);
		JV lp = JV::arr(), hand = JV::arr(), gy = JV::arr(), mons = JV::arr(), sets = JV::arr();
		for(int p = 0; p < 2; ++p) {
			lp.push(mr.end.lp[p]); hand.push(mr.end.hand[p]); gy.push(mr.end.gy[p]); sets.push(mr.end.st_set[p] + mr.end.st_up[p]);
			JV row = JV::arr();
			for(int z = 0; z < 5; ++z) {
				const Mon& mo = mr.end.m[p][z];
				if(!mo.there) continue;
				JV c = JV::obj(); c.set("code", mo.code); c.set("atk", mo.atk); c.set("def", mo.def); c.set("pos", mo.pos);
				row.push(std::move(c));
			}
			mons.push(std::move(row));
		}
		res.set("lp", std::move(lp)); res.set("hand", std::move(hand)); res.set("gy", std::move(gy)); res.set("st", std::move(sets)); res.set("mons", std::move(mons));
		JV pl = JV::arr(), lg = JV::arr();
		for(uint32_t c : mr.played) pl.push((int64_t)c);
		for(auto& l : mr.logs) lg.push(JV(l));
		res.set("played", std::move(pl)); res.set("logs", std::move(lg));
		encode(out, res);
		break; }
	case 34: {  // timing: how long a fresh duel takes to set up, and to replay (handle, repeats)
		Duel* d = find_duel(r.u32());
		uint32_t n = r.u32();
		if(!d) break;
		auto t0 = std::chrono::steady_clock::now();
		for(uint32_t i = 0; i < n; ++i) { auto sm = sim_new(d->hist); if(sm) sim_step(*sm); }
		auto t1 = std::chrono::steady_clock::now();
		for(uint32_t i = 0; i < n; ++i) { auto sm = sim_replay(d->hist); }
		auto t2 = std::chrono::steady_clock::now();
		put32(out, (uint32_t)std::chrono::duration<double, std::micro>(t1 - t0).count() / std::max<uint32_t>(1, n));
		put32(out, (uint32_t)std::chrono::duration<double, std::micro>(t2 - t1).count() / std::max<uint32_t>(1, n));
		put32(out, (uint32_t)d->hist.answers.size());
		break; }
	case 33: {  // a whole duel between two levels, no screen: for measuring how strong they are
		History h{};
		for(int i = 0; i < 4; ++i) h.opt.seed[i] = r.u64();
		h.opt.flags = r.u64();
		h.opt.team1.startingLP = r.u32(); h.opt.team1.startingDrawCount = r.u32(); h.opt.team1.drawCountPerTurn = 1;
		h.opt.team2.startingLP = r.u32(); h.opt.team2.startingDrawCount = r.u32(); h.opt.team2.drawCountPerTurn = 1;
		int level0 = (int)r.u32(), level1 = (int)r.u32(), ms = (int)r.u32(), max_turns = (int)r.u32();
		uint64_t seed = r.u64();
		uint64_t sh = mix(seed) | 1;
		for(int t = 0; t < 2; ++t) {
			for(int part = 0; part < 2; ++part) {
				uint32_t n = r.u32();
				std::vector<uint32_t> codes;
				for(uint32_t i = 0; i < n && !r.bad; ++i) codes.push_back(r.u32());
				if(part == 0) for(size_t i = codes.size(); i > 1; --i) { sh = mix(sh); std::swap(codes[i - 1], codes[sh % i]); }
				for(uint32_t c : codes) {
					OCG_NewCardInfo ci{}; ci.team = (uint8_t)t; ci.code = c; ci.con = (uint8_t)t; ci.loc = part == 0 ? 0x01 : 0x40; ci.pos = 0x8;
					h.cards.push_back(ci);
				}
			}
		}
		MatchResult mr = play_match(h, level0, level1, seed, ms, max_turns);
		put32(out, (uint32_t)mr.winner); put32(out, (uint32_t)mr.turns); put32(out, (uint32_t)mr.decisions); put32(out, (uint32_t)mr.sims);
		put32(out, (uint32_t)mr.think_ms); put32(out, (uint32_t)mr.max_ms); put32(out, (uint32_t)mr.refused);
		// then: every card that was played, and what the scripts complained about (for the sweep)
		put32(out, (uint32_t)mr.played.size());
		for(uint32_t c : mr.played) put32(out, c);
		JV logs = JV::arr();
		for(size_t i = 0; i < mr.logs.size() && i < 20; ++i) logs.push(mr.logs[i]);
		encode(out, logs);
		break; }
	default: break;
	}
	return out;
}

// ---------------------------------------------------------------- Godot glue
static GDExtensionInterfaceGetProcAddress g_get = nullptr;
static GDExtensionClassLibraryPtr g_lib = nullptr;
struct PBA { uint64_t a, b; };
struct SN { uint64_t a; };
static GDExtensionInterfaceStringNameNewWithLatin1Chars sn_new;
static GDExtensionInterfaceStringNewWithLatin1Chars str_new;
static GDExtensionPtrConstructor pba_ctor0, pba_copy;
static GDExtensionPtrDestructor pba_dtor;
static GDExtensionPtrBuiltInMethod pba_resize;
static GDExtensionInterfacePackedByteArrayOperatorIndex pba_index;
static GDExtensionInterfacePackedByteArrayOperatorIndexConst pba_index_const;
static GDExtensionTypeFromVariantConstructorFunc to_int, to_pba;
static GDExtensionVariantFromTypeConstructorFunc from_pba;

static void make_result(PBA* dst, int64_t code, const PBA* data, int64_t size) {
	const uint8_t* p = (size > 0) ? pba_index_const((GDExtensionConstTypePtr)data, 0) : nullptr;
	std::vector<uint8_t> out = run_op((int)code, p, p ? (size_t)size : 0);
	pba_ctor0(dst, nullptr);
	if(!out.empty()) {
		int64_t n = (int64_t)out.size(), ret = 0;
		GDExtensionConstTypePtr args[1] = { &n };
		pba_resize(dst, args, &ret, 1);
		uint8_t* w = pba_index(dst, 0);
		if(w) std::memcpy(w, out.data(), out.size());
	}
}
static void op_ptrcall(void*, GDExtensionClassInstancePtr, const GDExtensionConstTypePtr* args, GDExtensionTypePtr r_ret) {
	PBA res;
	make_result(&res, *(const int64_t*)args[0], (const PBA*)args[1], *(const int64_t*)args[2]);
	pba_dtor(r_ret);
	GDExtensionConstTypePtr cargs[1] = { &res };
	pba_copy(r_ret, cargs);
	pba_dtor(&res);
}
static void op_call(void*, GDExtensionClassInstancePtr, const GDExtensionConstVariantPtr* args, GDExtensionInt argc, GDExtensionVariantPtr r_return, GDExtensionCallError* r_error) {
	if(argc != 3) { r_error->error = argc < 3 ? GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS : GDEXTENSION_CALL_ERROR_TOO_MANY_ARGUMENTS; r_error->expected = 3; return; }
	int64_t code = 0, size = 0;
	PBA data, res;
	to_int(&code, (GDExtensionVariantPtr)args[0]);
	to_pba(&data, (GDExtensionVariantPtr)args[1]);
	to_int(&size, (GDExtensionVariantPtr)args[2]);
	make_result(&res, code, &data, size);
	from_pba(r_return, &res);
	pba_dtor(&res);
	pba_dtor(&data);
	r_error->error = GDEXTENSION_CALL_OK;
}
static void free_instance(void*, GDExtensionClassInstancePtr) {}

static void initialize(void*, GDExtensionInitializationLevel level) {
	if(level != GDEXTENSION_INITIALIZATION_SCENE) return;
	sn_new = (GDExtensionInterfaceStringNameNewWithLatin1Chars)g_get("string_name_new_with_latin1_chars");
	str_new = (GDExtensionInterfaceStringNewWithLatin1Chars)g_get("string_new_with_latin1_chars");
	auto get_ctor = (GDExtensionInterfaceVariantGetPtrConstructor)g_get("variant_get_ptr_constructor");
	auto get_dtor = (GDExtensionInterfaceVariantGetPtrDestructor)g_get("variant_get_ptr_destructor");
	auto get_method = (GDExtensionInterfaceVariantGetPtrBuiltinMethod)g_get("variant_get_ptr_builtin_method");
	auto get_to = (GDExtensionInterfaceGetVariantToTypeConstructor)g_get("get_variant_to_type_constructor");
	auto get_from = (GDExtensionInterfaceGetVariantFromTypeConstructor)g_get("get_variant_from_type_constructor");
	pba_index = (GDExtensionInterfacePackedByteArrayOperatorIndex)g_get("packed_byte_array_operator_index");
	pba_index_const = (GDExtensionInterfacePackedByteArrayOperatorIndexConst)g_get("packed_byte_array_operator_index_const");
	pba_ctor0 = get_ctor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, 0);
	pba_copy = get_ctor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, 1);
	pba_dtor = get_dtor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY);
	to_int = get_to(GDEXTENSION_VARIANT_TYPE_INT);
	to_pba = get_to(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY);
	from_pba = get_from(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY);
	static SN n_class, n_parent, n_op, n_resize, n_code, n_data, n_size, n_empty;
	static uint64_t s_empty;
	sn_new(&n_class, "OcgBridge", true); sn_new(&n_parent, "Object", true); sn_new(&n_op, "op", true); sn_new(&n_resize, "resize", true);
	sn_new(&n_code, "code", true); sn_new(&n_data, "data", true); sn_new(&n_size, "size", true); sn_new(&n_empty, "", true);
	str_new(&s_empty, "");
	pba_resize = get_method(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, &n_resize, 848867239);

	GDExtensionClassCreationInfo6 ci{};
	ci.is_abstract = true; ci.is_exposed = true;
	ci.free_instance_func = free_instance;
	((GDExtensionInterfaceClassdbRegisterExtensionClass6)g_get("classdb_register_extension_class6"))(g_lib, &n_class, &n_parent, &ci);

	static GDExtensionPropertyInfo ret = { GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, &n_empty, &n_empty, 0, &s_empty, 6 };
	static GDExtensionPropertyInfo args[3] = {
		{ GDEXTENSION_VARIANT_TYPE_INT, &n_code, &n_empty, 0, &s_empty, 6 },
		{ GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY, &n_data, &n_empty, 0, &s_empty, 6 },
		{ GDEXTENSION_VARIANT_TYPE_INT, &n_size, &n_empty, 0, &s_empty, 6 },
	};
	static GDExtensionClassMethodArgumentMetadata meta[3] = { GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE, GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE, GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE };
	GDExtensionClassMethodInfo mi{};
	mi.name = &n_op; mi.call_func = op_call; mi.ptrcall_func = op_ptrcall;
	mi.method_flags = GDEXTENSION_METHOD_FLAG_NORMAL | GDEXTENSION_METHOD_FLAG_STATIC;
	mi.has_return_value = true; mi.return_value_info = &ret; mi.return_value_metadata = GDEXTENSION_METHOD_ARGUMENT_METADATA_NONE;
	mi.argument_count = 3; mi.arguments_info = args; mi.arguments_metadata = meta;
	((GDExtensionInterfaceClassdbRegisterExtensionClassMethod)g_get("classdb_register_extension_class_method"))(g_lib, &n_class, &mi);
}
static void deinitialize(void*, GDExtensionInitializationLevel level) {
	if(level != GDEXTENSION_INITIALIZATION_SCENE) return;
	std::lock_guard<std::mutex> lock(g_mutex);
	g_duels.clear();
}

extern "C" {
#if defined(_WIN32)
__declspec(dllexport)
#else
__attribute__((visibility("default")))
#endif
GDExtensionBool ocg_bridge_init(GDExtensionInterfaceGetProcAddress p_get, GDExtensionClassLibraryPtr p_library, GDExtensionInitialization* r_init) {
	g_get = p_get; g_lib = p_library;
	r_init->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
	r_init->initialize = initialize;
	r_init->deinitialize = deinitialize;
	r_init->userdata = nullptr;
	return 1;
}
}
