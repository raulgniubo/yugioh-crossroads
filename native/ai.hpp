// The opponent's brain for the new engine. Included by bridge.cpp.
//
// How it thinks: for each answer it could give, it copies the duel (by replaying it from the
// start), re-deals everything it is not allowed to know (your hand, your Deck, your face-down
// cards that were never face-up), gives that answer, plays the next turns out with a simple
// steady policy for both sides, and scores where that leaves it. The real card scripts run in
// every one of those tries, so it works for every card. It never reads your hidden cards:
// each try uses a different random deal of them.
#include <chrono>
#include <thread>
#include <algorithm>
#include <cmath>
#include <map>
#include <set>
#include <atomic>

struct Sim {
	Duel d;
	int status = 2;
	JV ask;
	bool has_ask = false;
	int winner = -1;
	int turns = 0;
	int turn_player = 0;
	int phase = 0;
	bool retry = false;
	long steps = 0;
	int hint[2] = { 0, 0 };          // the last "select..." line each player was given
	int attacker_seq[2] = { -1, -1 }; // the monster each player last declared an attack with
	~Sim() { if(d.d) OCG_DestroyDuel(d.d); }
};

static bool is_select(int t) { return (t >= 10 && t <= 26) || (t >= 140 && t <= 143) || t == 132; }

// Run until the duel waits or ends. Only the question is read in full; the rest is skimmed.
static void sim_step(Sim& s) {
	s.has_ask = false;
	s.retry = false;
	for(int guard = 0; guard < 20000; ++guard) {
		s.status = OCG_DuelProcess(s.d.d);
		uint32_t len = 0;
		auto* buf = (const uint8_t*)OCG_DuelGetMessage(s.d.d, &len);
		size_t pos = 0;
		while(buf && pos + 4 <= len) {
			uint32_t l; std::memcpy(&l, buf + pos, 4); pos += 4;
			if(pos + l > len || l == 0) { pos += l; continue; }
			int t = buf[pos];
			if(t == 5 && l >= 2) s.winner = buf[pos + 1];
			else if(t == 40 && l >= 2) { s.turns++; s.turn_player = buf[pos + 1]; }
			else if(t == 41 && l >= 3) s.phase = buf[pos + 1] | (buf[pos + 2] << 8);
			else if(t == 1) s.retry = true;
			else if(t == 2 && l >= 11 && buf[pos + 1] == 3 && buf[pos + 2] < 2) { uint64_t hv; std::memcpy(&hv, buf + pos + 3, 8); s.hint[buf[pos + 2]] = (int)hv; }
			else if(is_select(t)) { s.ask = parse_msg(buf + pos, l); s.has_ask = true; }
			pos += l;
		}
		if(s.status != OCG_DUEL_STATUS_CONTINUE) break;
	}
	s.steps++;
}

static std::unique_ptr<Sim> sim_new(const History& h) {
	auto s = std::make_unique<Sim>();
	OCG_DuelOptions o = h.opt;
	o.cardReader = card_reader; o.scriptReader = script_reader; o.logHandler = log_handler; o.cardReaderDone = card_reader_done;
	o.payload2 = &s->d; o.payload3 = &s->d;
	if(OCG_CreateDuel(&s->d.d, &o) != 0 || !s->d.d) return nullptr;
	for(const char* f : { "constant.lua", "utility.lua" }) script_reader(&s->d, s->d.d, f);
	for(auto& sc : h.scripts) OCG_LoadScript(s->d.d, sc.second.data(), (uint32_t)sc.second.size(), sc.first.c_str());
	for(auto& c : h.cards) OCG_DuelNewCard(s->d.d, &c);
	OCG_StartDuel(s->d.d);
	return s;
}

// A copy of the duel as it stands: the same start, the same answers.
static std::unique_ptr<Sim> sim_replay(const History& h) {
	auto s = sim_new(h);
	if(!s) return nullptr;
	for(auto& a : h.answers) {
		sim_step(*s);
		if(s->status != OCG_DUEL_STATUS_AWAITING) return s;
		if(s->has_ask && s->ask.geti("t") == 10 && a.size() >= 4) {
			int32_t v; std::memcpy(&v, a.data(), 4);
			int p = (int)s->ask.geti("p");
			if((v & 0xffff) == 1 && p >= 0 && p < 2) {
				const JV* at = s->ask.get("attacks");
				size_t i = (size_t)(v >> 16);
				s->attacker_seq[p] = (at && i < at->a.size()) ? (int)at->a[i].geti("seq") : -1;
			}
		}
		OCG_DuelSetResponse(s->d.d, a.data(), (uint32_t)a.size());
	}
	sim_step(*s);
	return s;
}

static const CardRow* row_of(uint32_t code) { auto it = g_cards.find(code); return it == g_cards.end() ? nullptr : &it->second; }
static int base_atk(uint32_t code) { auto* r = row_of(code); return r ? std::max(0, r->atk) : 0; }
static int base_def(uint32_t code) { auto* r = row_of(code); return r ? std::max(0, r->def) : 0; }
static uint32_t base_type(uint32_t code) { auto* r = row_of(code); return r ? r->type : 0; }

// ---------------------------------------------------------------- what is on the table
struct Mon { bool there = false; uint32_t code = 0; int pos = 0; int atk = 0, def = 0; uint32_t type = 0; int level = 0; };
struct Board {
	Mon m[2][7];
	int lp[2] = { 0, 0 };
	int hand[2] = { 0, 0 }, deck[2] = { 0, 0 }, gy[2] = { 0, 0 }, extra[2] = { 0, 0 };
	int st_set[2] = { 0, 0 }, st_up[2] = { 0, 0 };
	int st_plain[2] = { 0, 0 };   // of the Set cards, the ones that are plain Spells (not Traps, not Quick-Play)
	int max_atk(int p) const { int v = 0; for(auto& x : m[p]) if(x.there && (x.pos & 0x5)) v = std::max(v, x.atk); return v; }
	int count(int p) const { int n = 0; for(auto& x : m[p]) if(x.there) n++; return n; }
};

static Board read_board(Sim& s) {
	Board b;
	uint32_t len = 0;
	auto* buf = (const uint8_t*)OCG_DuelQueryField(s.d.d, &len);
	R q(buf, buf ? len : 0);
	q.u32();
	for(int p = 0; p < 2; ++p) {
		b.lp[p] = (int32_t)q.u32();
		for(int z = 0; z < 7; ++z) { if(q.u8()) { b.m[p][z].there = true; b.m[p][z].pos = q.u8(); q.u32(); } }
		for(int z = 0; z < 8; ++z) { if(q.u8()) { int pos = q.u8(); q.u32(); if(z < 5) { if(pos & 0x5) b.st_up[p]++; else b.st_set[p]++; } } }
		b.deck[p] = q.u32(); b.hand[p] = q.u32(); b.gy[p] = q.u32(); q.u32(); b.extra[p] = q.u32(); q.u32();
	}
	for(int p = 0; p < 2; ++p) {
		OCG_QueryInfo qs{}; qs.flags = 0x1 | 0x2; qs.con = (uint8_t)p; qs.loc = 0x08;
		uint32_t l3 = 0;
		auto* b3 = (const uint8_t*)OCG_DuelQueryLocation(s.d.d, &l3, &qs);
		if(b3 && l3 >= 4) {
			R r3(b3 + 4, l3 - 4);
			for(int z = 0; z < 5 && r3.left() >= 2; ++z) {
				uint32_t code = 0; uint32_t pos = 0;
				for(;;) {
					uint16_t size = r3.u16();
					if(size == 0) break;
					uint32_t flag = r3.u32();
					size_t end = r3.pos + (size - 4);
					if(flag == 0x80000000u) break;
					if(flag == 0x1) code = r3.u32(); else if(flag == 0x2) pos = r3.u32();
					if(end <= r3.n) r3.pos = end; else break;
				}
				if(code && !(pos & 0x5)) { uint32_t ty = base_type(code); if((ty & 0x2) && !(ty & 0x10000)) b.st_plain[p]++; }
			}
		}
		OCG_QueryInfo qi{}; qi.flags = 0x1 | 0x8 | 0x10 | 0x20 | 0x100 | 0x200; qi.con = (uint8_t)p; qi.loc = 0x04;
		uint32_t l2 = 0;
		auto* b2 = (const uint8_t*)OCG_DuelQueryLocation(s.d.d, &l2, &qi);
		if(!b2 || l2 < 4) continue;
		R r(b2 + 4, l2 - 4);
		for(int z = 0; z < 7 && r.left() >= 2; ++z) {
			Mon& mo = b.m[p][z];
			for(;;) {
				uint16_t size = r.u16();
				if(size == 0) break;
				uint32_t flag = r.u32();
				size_t end = r.pos + (size - 4);
				if(flag == 0x80000000u) break;
				if(flag == 0x1) mo.code = r.u32();
				else if(flag == 0x8) mo.type = r.u32();
				else if(flag == 0x10) { int v = (int)r.u32(); if(v) mo.level = v; }
				else if(flag == 0x20) { int v = (int)r.u32(); if(v) mo.level = v; }
				else if(flag == 0x100) mo.atk = std::max(0, r.i32());
				else if(flag == 0x200) mo.def = std::max(0, r.i32());
				if(end <= r.n) r.pos = end; else break;
			}
		}
	}
	return b;
}

static double lp_worth(int lp) { if(lp <= 0) return 0.0; int v = std::min(lp, 16000); return 0.30 * v + 1600.0 * std::sqrt(v / 8000.0); }

// How good the table is for `me`. Higher is better.
static double evaluate(const Board& b, int me) {
	int op = 1 - me;
	double v = lp_worth(b.lp[me]) - lp_worth(b.lp[op]);
	for(auto& x : b.m[me]) {
		if(!x.there) continue;
		if(x.pos & 0x1) v += 0.95 * x.atk + 300;
		else if(x.pos & 0x4) v += 0.5 * std::max(x.def, (int)(x.atk * 0.8)) + 250;
		else v += 0.45 * x.def + 300;
	}
	for(auto& x : b.m[op]) {
		if(!x.there) continue;
		if(x.pos & 0x1) v -= 1.0 * x.atk + 350;
		else if(x.pos & 0x4) v -= 0.55 * x.def + 0.3 * x.atk + 250;
		else v -= 700;
	}
	v += 520.0 * b.hand[me] - 520.0 * b.hand[op];
	// Its own Set cards it knows: a Trap or a Quick-Play is better Set than held, a plain Spell is not.
	v += 600.0 * (b.st_set[me] - b.st_plain[me]) + 470.0 * b.st_plain[me] - 640.0 * b.st_set[op];
	v += 420.0 * b.st_up[me] - 440.0 * b.st_up[op];
	if(b.deck[me] == 0) v -= 2500;
	if(b.deck[op] == 0) v += 2500;
	return v;
}

// ---------------------------------------------------------------- the steady policy
static std::vector<uint8_t> bytes_i32(int32_t v) { std::vector<uint8_t> b(4); std::memcpy(b.data(), &v, 4); return b; }
static std::vector<uint8_t> bytes_pick(const std::vector<int>& idx) {
	std::vector<uint8_t> b(8 + 4 * idx.size());
	int32_t z = 0; uint32_t n = (uint32_t)idx.size();
	std::memcpy(b.data(), &z, 4); std::memcpy(b.data() + 4, &n, 4);
	for(size_t i = 0; i < idx.size(); ++i) { uint32_t v = (uint32_t)idx[i]; std::memcpy(b.data() + 8 + 4 * i, &v, 4); }
	return b;
}
static std::vector<uint8_t> bytes_pick_one(int idx) { std::vector<uint8_t> b(8); int32_t a = 1, i = idx; std::memcpy(b.data(), &a, 4); std::memcpy(b.data() + 4, &i, 4); return b; }


struct PMemo {
	int turn = -1, who = -1, acts = 0, sets = 0;
	std::set<std::string> done;
	std::map<int, int> skip;
	std::map<std::string, int> chains;
	int target_seq = -1;     // the monster it means to attack (their zone), for the question that follows
	int announce = 0;
	void fresh(int t, int w) { if(turn != t || who != w) { *this = PMemo(); turn = t; who = w; } }
};

static const JV& arr(const JV& m, const char* k) { static JV none = JV::arr(); auto* v = m.get(k); return v ? *v : none; }

// A card of a question, with what is known about it.
struct CardRef { uint32_t code; int con, loc, seq; };
static CardRef ref_of(const JV& e) { return { (uint32_t)e.geti("code"), (int)e.geti("con"), (int)e.geti("loc"), (int)e.geti("seq") }; }
static int card_power(const Board& b, const CardRef& c) {
	if((c.loc & 0x7f) == 0x04 && c.con < 2 && c.seq < 7 && b.m[c.con][c.seq].there) return std::max(b.m[c.con][c.seq].atk, 1);
	uint32_t t = base_type(c.code);
	if(t & 0x1) return base_atk(c.code) + 1;
	return 800;
}

static std::vector<uint8_t> policy_place(const JV& m) {
	int p = (int)m.geti("p");
	uint32_t flag = (uint32_t)m.geti("flag");
	int want = std::max<int>(1, (int)m.geti("count"));
	static const int pref[8] = { 2, 1, 3, 0, 4, 5, 6, 7 };
	std::vector<uint8_t> out;
	for(int side = 0; side < 2 && want > 0; ++side)
		for(int li = 0; li < 2 && want > 0; ++li)
			for(int k = 0; k < 8 && want > 0; ++k) {
				int s = pref[k];
				if(li == 0 && s > 6) continue;
				int bit = s + (li == 0 ? 0 : 8) + (side == 0 ? 0 : 16);
				if(!((flag >> bit) & 1)) { out.push_back((uint8_t)(side == 0 ? p : 1 - p)); out.push_back(li == 0 ? 0x04 : 0x08); out.push_back((uint8_t)s); want--; }
			}
	return out;
}

static bool sum_exact(const std::vector<int>& params, size_t i, int acc) {
	if(i == params.size()) return acc == 0;
	if(acc <= 0) return false;
	int o1 = params[i] & 0xffff, o2 = params[i] >> 16;
	if(sum_exact(params, i + 1, acc - o1)) return true;
	return o2 > 0 && sum_exact(params, i + 1, acc - o2);
}
static std::vector<uint8_t> policy_sum(const JV& m) {
	int acc = (int)m.geti("acc");
	const JV& must = arr(m, "must"); const JV& list = arr(m, "cards");
	bool exact = m.geti("mode") == 0;
	int lo = (int)m.geti("min"), hi = (int)m.geti("max");
	int n = std::min<int>((int)list.a.size(), 14);
	for(int mask = 1; mask < (1 << n); ++mask) {
		std::vector<int> picks, params;
		for(auto& c : must.a) params.push_back((int)c.geti("param"));
		for(int i = 0; i < n; ++i) if(mask & (1 << i)) { picks.push_back(i); params.push_back((int)list.a[i].geti("param")); }
		if(exact) {
			if((int)picks.size() < lo || (int)picks.size() > hi) continue;
			if(sum_exact(params, 0, acc)) return bytes_pick(picks);
		} else {
			int total = 0, most = 0, least = 0x7fffffff;
			for(int pv : params) { int o1 = pv & 0xffff, o2 = pv >> 16; int small = (o2 > 0 && o2 < o1) ? o2 : o1; total += small; most += std::max(o1, o2); least = std::min(least, small); }
			if(most >= acc && total - least < acc) return bytes_pick(picks);
		}
	}
	std::vector<int> all;
	for(int i = 0; i < std::min<int>(std::max(lo, 1), (int)list.a.size()); ++i) all.push_back(i);
	return bytes_pick(all);
}

// Remember what an answer meant, for the question that follows it (an attack, then its target).
static void note_answer(Sim& s, const JV& ask, const std::vector<uint8_t>& ans) {
	if(ask.geti("t") != 10 || ans.size() < 4) return;
	int32_t v; std::memcpy(&v, ans.data(), 4);
	int p = (int)ask.geti("p");
	if(p < 0 || p > 1) return;
	if((v & 0xffff) == 1) {
		const JV* at = ask.get("attacks");
		size_t i = (size_t)(v >> 16);
		s.attacker_seq[p] = (at && i < at->a.size()) ? (int)at->a[i].geti("seq") : -1;
	}
}

// The answer the steady policy gives. `safe`: the plainest legal answer (after a refusal).
// mode 0: plays everything it holds (the basic opponent). mode 1: the line a duel is played out
// with when the thinking opponent weighs an answer: bring out monsters, attack what can be
// beaten, set Traps, and use a card's effect only in answer to something. Nothing is thrown away
// in that line, so what an answer is worth is not blurred by what comes after it.
static std::vector<uint8_t> policy(Sim& s, const JV& m, PMemo& mm, bool safe, uint64_t& rnd, int mode = 0) {
	int t = (int)m.geti("t");
	int p = (int)m.geti("p");
	mm.fresh(s.turns, s.turn_player);
	switch(t) {
	case 11: {
		bool to_ep = m.geti("to_ep") != 0, to_bp = m.geti("to_bp") != 0;
		auto leave = bytes_i32(to_ep ? 7 : 6);
		if(safe) return leave;
		int acts = mm.acts++;
		Board b = read_board(s);
		if(acts < 25) {
			const JV& sp = arr(m, "spsummon");
			int best = -1;
			for(size_t i = 0; i < sp.a.size(); ++i) {
				uint32_t code = (uint32_t)sp.a[i].geti("code");
				std::string key = "sp" + std::to_string(code);
				if(mm.done.count(key + "b")) continue;
				if(best == -1 || base_atk(code) > base_atk((uint32_t)sp.a[best].geti("code"))) best = (int)i;
			}
			if(best != -1) {
				std::string key = "sp" + std::to_string(sp.a[best].geti("code"));
				if(mm.done.count(key)) mm.done.insert(key + "b"); else mm.done.insert(key);
				return bytes_i32((best << 16) | 1);
			}
			const JV& ns = arr(m, "summon");
			const JV& ms = arr(m, "mset");
			best = -1;
			// What a Tribute Summon would cost: its weakest monsters, one for Level 5-6, two from Level 7.
			std::vector<int> mine;
			for(auto& x : b.m[p]) if(x.there) mine.push_back((x.pos & 0x5) ? x.atk : x.def / 2);
			std::sort(mine.begin(), mine.end());
			for(size_t i = 0; i < ns.a.size(); ++i) {
				uint32_t code = (uint32_t)ns.a[i].geti("code");
				if(mode == 1) {
					auto* row = row_of(code);
					int lvl = row ? (int)(row->level & 0xff) : 4;
					size_t need = lvl >= 7 ? 2 : (lvl >= 5 ? 1 : 0);
					if(need > 0 && mine.size() >= need) {
						int paid = 0, top = 0;
						for(size_t k = 0; k < need; ++k) { paid += mine[k] + 300; top = std::max(top, mine[k]); }
						// Not worth it when it gives up as much as it brings.
						if(base_atk(code) <= top || base_atk(code) + 300 < paid * 0.8) continue;
					}
				}
				if(best == -1 || base_atk(code) > base_atk((uint32_t)ns.a[best].geti("code"))) best = (int)i;
			}
			if(best != -1 && !mm.done.count("ns")) {
				mm.done.insert("ns");
				uint32_t code = (uint32_t)ns.a[best].geti("code");
				int atk = base_atk(code), def = base_def(code);
				// A weak monster with a better back, or one that would only be run over, goes face-down.
				if((atk < 1000 && def > atk) || (atk < b.max_atk(1 - p) && def > atk && def >= 1500)) {
					for(size_t j = 0; j < ms.a.size(); ++j)
						if((uint32_t)ms.a[j].geti("code") == code) return bytes_i32(((int)j << 16) | 3);
				}
				return bytes_i32((best << 16) | 0);
			}
			const JV& ch = arr(m, "chains");
			for(size_t i = 0; mode == 0 && i < ch.a.size(); ++i) {
				std::string key = "ac" + std::to_string(ch.a[i].geti("code")) + "_" + std::to_string(ch.a[i].geti("desc"));
				if(mm.done.count(key)) continue;
				mm.done.insert(key);
				return bytes_i32(((int)i << 16) | 5);
			}
			if(ns.a.empty() && !ms.a.empty() && !mm.done.count("ns")) {
				mm.done.insert("ns");
				return bytes_i32((0 << 16) | 3);
			}
			const JV& ss = arr(m, "sset");
			if(mm.sets < 5) {
				for(size_t i = 0; i < ss.a.size(); ++i) {
					uint32_t code = (uint32_t)ss.a[i].geti("code");
					std::string key = "ss" + std::to_string(ss.a[i].geti("seq")) + "_" + std::to_string(code);
					if(mm.done.count(key)) continue;
					uint32_t ty = base_type(code);
					if((ty & 0x4) || (ty & 0x10000)) { mm.done.insert(key); mm.sets++; return bytes_i32(((int)i << 16) | 4); }
				}
			}
			// Turn a monster that is about to be run over to Defense, and a safe wall back to Attack.
			const JV& rp = arr(m, "repos");
			int foe = b.max_atk(1 - p);
			for(size_t i = 0; i < rp.a.size(); ++i) {
				int seq = (int)rp.a[i].geti("seq");
				if(seq > 6) continue;
				const Mon& mo = b.m[p][seq];
				std::string key = "rp" + std::to_string(seq);
				if(!mo.there || mm.done.count(key)) continue;
				bool to_def = (mo.pos & 0x1) && foe > mo.atk && mo.def >= mo.atk && b.count(1 - p) > 0;
				bool to_atk = (mo.pos & 0x4) && mo.atk >= 1500 && mo.atk > foe;
				if(to_def || to_atk) { mm.done.insert(key); return bytes_i32(((int)i << 16) | 2); }
			}
		}
		if(to_bp && !mm.done.count("bp")) {
			mm.done.insert("bp");
			for(auto& x : b.m[p]) if(x.there && (x.pos & 0x1)) return bytes_i32(6);
		}
		return leave;
	}
	case 10: {
		const JV& at = arr(m, "attacks");
		bool to_m2 = m.geti("to_m2") != 0, to_ep = m.geti("to_ep") != 0;
		auto leave = bytes_i32(to_m2 ? 2 : 3);
		if(!to_m2 && !to_ep) {
			if(!at.a.empty()) return bytes_i32(1);
			if(!arr(m, "chains").a.empty()) return bytes_i32(0);
		}
		if(safe) return leave;
		Board b = read_board(s);
		int foes = b.count(1 - p);
		if(mode == 1 && foes > 0) {
			// Their biggest monster that can be beaten goes to the weakest of its monsters that beats it,
			// so the strong ones are still there for what is left.
			std::vector<int> order;
			for(int z = 0; z < 7; ++z) if(b.m[1 - p][z].there && (b.m[1 - p][z].pos & 0x5)) order.push_back(z);
			std::sort(order.begin(), order.end(), [&](int a, int c) { return b.m[1 - p][a].atk > b.m[1 - p][c].atk; });
			for(int z : order) {
				const Mon& f = b.m[1 - p][z];
				int wall = (f.pos & 0x1) ? f.atk : f.def;
				int pick_i = -1, pick_power = 1 << 30;
				for(size_t i = 0; i < at.a.size(); ++i) {
					int seq = (int)at.a[i].geti("seq");
					if(seq > 6 || mm.skip.count(seq) || at.a[i].geti("direct") != 0) continue;
					int power = b.m[p][seq].atk;
					if(power > wall && power < pick_power) { pick_power = power; pick_i = (int)i; }
				}
				if(pick_i != -1) {
					mm.skip[(int)at.a[pick_i].geti("seq")] = 1;
					mm.target_seq = z;
					return bytes_i32((pick_i << 16) | 1);
				}
			}
		}
		for(size_t i = 0; i < at.a.size(); ++i) {
			int seq = (int)at.a[i].geti("seq");
			if(seq > 6 || mm.skip.count(seq)) continue;
			int power = b.m[p][seq].atk;
			if(foes == 0 || at.a[i].geti("direct") != 0) { mm.target_seq = -1; mm.skip[seq] = 1; return bytes_i32(((int)i << 16) | 1); }
			int pick = -1;
			for(int z = 0; z < 7; ++z) {
				const Mon& f = b.m[1 - p][z];
				if(!f.there) continue;
				bool beat = false;
				if(!(f.pos & 0x5)) beat = power >= 1600;
				else if(f.pos & 0x1) beat = power > f.atk;
				else beat = power > f.def;
				if(beat && (pick == -1 || f.atk > b.m[1 - p][pick].atk)) pick = z;
			}
			mm.skip[seq] = 1;
			if(pick != -1) { mm.target_seq = pick; return bytes_i32(((int)i << 16) | 1); }
		}
		return leave;
	}
	case 12: case 13: return bytes_i32(safe ? 0 : 1);
	case 14: return bytes_i32(0);
	case 15: {
		const JV& list = arr(m, "cards");
		int lo = (int)m.geti("min"), hi = (int)m.geti("max");
		int n = hi >= 1 ? std::max(lo, 1) : 0;
		std::vector<int> order;
		for(size_t i = 0; i < list.a.size(); ++i) order.push_back((int)i);
		if(safe) { order.resize(std::min<size_t>(order.size(), (size_t)std::max(lo, 1))); return bytes_pick(order); }
		if(mm.target_seq >= 0) {
			int want = mm.target_seq; mm.target_seq = -1;
			for(size_t i = 0; i < list.a.size(); ++i)
				if((int)list.a[i].geti("con") == 1 - p && ((int)list.a[i].geti("loc") & 0x7f) == 0x04 && (int)list.a[i].geti("seq") == want) return bytes_pick({ (int)i });
		}
		Board b = read_board(s);
		if(s.hint[p] == 549 && s.attacker_seq[p] >= 0 && s.attacker_seq[p] < 7 && b.m[p][s.attacker_seq[p]].there) {
			// An attack target: the biggest monster the attacker beats, else the one that costs it least.
			int power = b.m[p][s.attacker_seq[p]].atk;
			int pick = -1; double pick_v = -1e18;
			for(size_t i = 0; i < list.a.size(); ++i) {
				int con = (int)list.a[i].geti("con"), seq = (int)list.a[i].geti("seq");
				if(con != 1 - p || ((int)list.a[i].geti("loc") & 0x7f) != 0x04 || seq > 6 || !b.m[con][seq].there) continue;
				const Mon& f = b.m[con][seq];
				double v;
				if(!(f.pos & 0x5)) v = power >= 1600 ? 300 : -600;
				else if(f.pos & 0x1) v = power > f.atk ? 1000 + f.atk : (power == f.atk ? -200 : -2000 - (f.atk - power));
				else v = power > f.def ? 600 + f.def * 0.3 : (power == f.def ? -50 : -500 - (f.def - power));
				if(v > pick_v) { pick_v = v; pick = (int)i; }
			}
			if(pick != -1) return bytes_pick({ pick });
		}
		std::vector<int> score(list.a.size());
		for(size_t i = 0; i < list.a.size(); ++i) score[i] = card_power(b, ref_of(list.a[i]));
		// Theirs first and the strongest of them; of mine, the weakest (it is usually a price).
		std::stable_sort(order.begin(), order.end(), [&](int a, int c) {
			bool ma = (int)list.a[a].geti("con") == p, mc = (int)list.a[c].geti("con") == p;
			if(ma != mc) return mc;
			if(ma) { int la = (int)list.a[a].geti("loc") & 0x7f; if(la == 0x04 || la == 0x02 || la == 0x08) return score[a] < score[c]; }
			return score[a] > score[c];
		});
		order.resize(std::min<size_t>(order.size(), (size_t)n));
		return bytes_pick(order);
	}
	case 16: {
		const JV& ch = arr(m, "chains");
		if(ch.a.empty()) return bytes_i32(-1);
		if(m.geti("forced") != 0) return bytes_i32(0);
		if(safe) return bytes_i32(-1);
		if(mode == 1 && m.geti("spe") == 0) return bytes_i32(-1);
		for(size_t i = 0; i < ch.a.size(); ++i) {
			std::string key = std::to_string(ch.a[i].geti("code")) + "_" + std::to_string(ch.a[i].geti("desc"));
			int used = mm.chains[key];
			if(used >= 2) continue;
			mm.chains[key] = used + 1;
			return bytes_i32((int)i);
		}
		return bytes_i32(-1);
	}
	case 18: case 24: return policy_place(m);
	case 19: {
		int ok = (int)m.geti("positions");
		uint32_t code = (uint32_t)m.geti("code");
		int atk = base_atk(code), def = base_def(code);
		if((ok & 1) && (atk >= def || atk >= 1500 || !(ok & 4))) return bytes_i32(1);
		for(int bit : { 4, 8, 1, 2 }) if(ok & bit) return bytes_i32(bit);
		return bytes_i32(1);
	}
	case 20: {
		const JV& list = arr(m, "cards");
		Board b = read_board(s);
		std::vector<int> order;
		for(size_t i = 0; i < list.a.size(); ++i) order.push_back((int)i);
		std::stable_sort(order.begin(), order.end(), [&](int a, int c) { return card_power(b, ref_of(list.a[a])) < card_power(b, ref_of(list.a[c])); });
		int need = (int)m.geti("min"), got = 0;
		std::vector<int> picks;
		for(int i : order) {
			if(got >= need || (int)picks.size() >= (int)m.geti("max")) break;
			picks.push_back(i);
			got += std::max<int>(1, (int)list.a[i].geti("param", 1));
		}
		return bytes_pick(picks);
	}
	case 21: case 25: return std::vector<uint8_t>{ 255 };
	case 22: {
		int left = (int)m.geti("count");
		std::vector<uint8_t> out;
		for(auto& c : arr(m, "cards").a) { int take = std::min<int>(left, (int)c.geti("n")); left -= take; out.push_back(take & 0xff); out.push_back((take >> 8) & 0xff); }
		return out;
	}
	case 23: return policy_sum(m);
	case 26: {
		if(m.geti("finish") != 0) return bytes_i32(-1);
		if(arr(m, "cards").a.empty() || safe) { if(m.geti("cancel") != 0) return bytes_i32(-1); }
		return bytes_pick_one(0);
	}
	case 132: { rnd ^= rnd << 13; rnd ^= rnd >> 7; rnd ^= rnd << 17; return bytes_i32(1 + (int)(rnd % 3)); }
	case 140: case 141: {
		uint64_t avail = (uint64_t)m.geti("avail"); int want = (int)m.geti("count"); uint64_t out = 0;
		for(uint64_t bit = 1; want > 0 && bit != 0 && bit <= avail; bit <<= 1) if(avail & bit) { out |= bit; want--; }
		std::vector<uint8_t> b(t == 140 ? 8 : 4);
		std::memcpy(b.data(), &out, b.size());
		return b;
	}
	case 142: {
		// Name a card: one it can see on their side, else a staple.
		Board b = read_board(s);
		std::vector<uint32_t> pool;
		for(auto& x : b.m[1 - p]) if(x.there && x.code && (x.pos & 0x5)) pool.push_back(x.code);
		for(auto& c : { 55144522u, 83764718u, 44095762u, 5318639u }) pool.push_back(c);
		return bytes_i32((int32_t)pool[(mm.announce++) % pool.size()]);
	}
	case 143: return bytes_i32(0);
	}
	return bytes_i32(0);
}

// ---------------------------------------------------------------- playing a line out
struct Roll { double score; bool ended; };

// Play on with the steady policy for both sides until `until_turns` turns have started (or the duel ends).
static Roll rollout(Sim& s, int me, int until_turns, uint64_t rnd, int max_steps, int mode) {
	PMemo memo[2];
	int refused = 0;
	for(int step = 0; step < max_steps; ++step) {
		if(s.winner != -1 || s.status == OCG_DUEL_STATUS_END) break;
		if(!s.has_ask) break;
		if(s.turns >= until_turns) break;
		int p = (int)s.ask.geti("p");
		if(p < 0 || p > 1) break;
		bool safe = s.retry;
		if(safe && ++refused > 6) break;
		auto ans = policy(s, s.ask, memo[p], safe, rnd, mode);
		note_answer(s, s.ask, ans);
		OCG_DuelSetResponse(s.d.d, ans.data(), (uint32_t)ans.size());
		sim_step(s);
	}
	if(s.winner != -1) {
		if(s.winner == me) return { 1e6 - 500.0 * s.turns, true };
		if(s.winner == 1 - me) return { -1e6 + 500.0 * s.turns, true };
		return { 0, true };
	}
	return { evaluate(read_board(s), me), false };
}

// ---------------------------------------------------------------- the answers worth trying
struct Cand { std::vector<uint8_t> bytes; std::string key; };

static void add_cand(std::vector<Cand>& out, std::set<std::string>& seen, std::vector<uint8_t> bytes, const std::string& key, size_t cap) {
	if(seen.count(key) || out.size() >= cap) return;
	seen.insert(key);
	out.push_back({ std::move(bytes), key });
}

static std::vector<Cand> candidates(Sim& s, const JV& m, size_t cap) {
	std::vector<Cand> out;
	std::set<std::string> seen;
	int t = (int)m.geti("t");
	auto key_of = [](const char* k, const JV& e) {
		int loc = (int)e.geti("loc") & 0x7f;
		// Two copies of a card in the hand or Deck are the same choice; cards on the table are not.
		std::string where = (loc == 0x04 || loc == 0x08) ? std::to_string(e.geti("con")) + "." + std::to_string(loc) + "." + std::to_string(e.geti("seq")) : std::to_string(loc);
		return std::string(k) + std::to_string(e.geti("code")) + "@" + where + "#" + std::to_string(e.geti("desc"));
	};
	switch(t) {
	case 11: {
		const char* names[6] = { "summon", "spsummon", "repos", "mset", "sset", "chains" };
		int order[6] = { 1, 5, 0, 3, 4, 2 };
		for(int oi = 0; oi < 6; ++oi) {
			int k = order[oi];
			const JV& l = arr(m, names[k]);
			for(size_t i = 0; i < l.a.size(); ++i) add_cand(out, seen, bytes_i32(((int)i << 16) | k), key_of(names[k], l.a[i]), cap - 2);
		}
		if(m.geti("to_bp") != 0) add_cand(out, seen, bytes_i32(6), "bp", cap);
		if(m.geti("to_ep") != 0) add_cand(out, seen, bytes_i32(7), "ep", cap);
		break; }
	case 10: {
		const JV& at = arr(m, "attacks");
		for(size_t i = 0; i < at.a.size(); ++i) add_cand(out, seen, bytes_i32(((int)i << 16) | 1), key_of("at", at.a[i]), cap - 2);
		const JV& ch = arr(m, "chains");
		for(size_t i = 0; i < ch.a.size(); ++i) add_cand(out, seen, bytes_i32(((int)i << 16) | 0), key_of("ch", ch.a[i]), cap - 2);
		if(m.geti("to_m2") != 0) add_cand(out, seen, bytes_i32(2), "m2", cap);
		if(m.geti("to_ep") != 0) add_cand(out, seen, bytes_i32(3), "ep", cap);
		break; }
	case 12: case 13:
		add_cand(out, seen, bytes_i32(1), "y", cap); add_cand(out, seen, bytes_i32(0), "n", cap);
		break;
	case 14: {
		const JV& o = arr(m, "opts");
		for(size_t i = 0; i < o.a.size(); ++i) add_cand(out, seen, bytes_i32((int)i), "o" + std::to_string(i), cap);
		break; }
	case 15: {
		const JV& l = arr(m, "cards");
		int lo = (int)m.geti("min"), hi = (int)m.geti("max");
		if(lo == 1 && hi == 1) {
			for(size_t i = 0; i < l.a.size(); ++i) add_cand(out, seen, bytes_pick({ (int)i }), key_of("c", l.a[i]), cap);
		} else if(lo <= 1 && hi > 1 && l.a.size() <= 6) {
			// A few cards, any number of them: each one alone, and all of them.
			for(size_t i = 0; i < l.a.size(); ++i) add_cand(out, seen, bytes_pick({ (int)i }), key_of("c", l.a[i]), cap - 1);
			std::vector<int> all;
			for(int i = 0; i < std::min<int>(hi, (int)l.a.size()); ++i) all.push_back(i);
			add_cand(out, seen, bytes_pick(all), "all", cap);
		}
		if(m.geti("cancel") != 0 && lo == 0) add_cand(out, seen, bytes_i32(-1), "none", cap + 1);
		break; }
	case 16: {
		const JV& ch = arr(m, "chains");
		bool forced = m.geti("forced") != 0;
		if(!forced) add_cand(out, seen, bytes_i32(-1), "pass", cap);
		for(size_t i = 0; i < ch.a.size(); ++i) add_cand(out, seen, bytes_i32((int)i), key_of("ch", ch.a[i]), cap);
		break; }
	case 19: {
		int ok = (int)m.geti("positions");
		for(int bit : { 1, 4, 8, 2 }) if(ok & bit) add_cand(out, seen, bytes_i32(bit), "p" + std::to_string(bit), cap);
		break; }
	case 26: {
		const JV& l = arr(m, "cards");
		if(m.geti("finish") != 0) add_cand(out, seen, bytes_i32(-1), "done", cap);
		for(size_t i = 0; i < l.a.size(); ++i) add_cand(out, seen, bytes_pick_one((int)i), key_of("u", l.a[i]), cap);
		break; }
	default: break;
	}
	(void)s;
	return out;
}

// ---------------------------------------------------------------- deciding
struct Level { int worlds; size_t cap; int ms; int horizon; double slip; int deal; double bias; int mode; double margin; int threads; int deep; };
// worlds: how many different deals of your hidden cards each answer is tried against (at most).
// horizon: how many more turns start before a line is scored. deal: what is re-dealt (see
// OCG_DuelDeterminize). margin: how much better than the steady answer another has to be.
// deep: how many of the best answers get a second look, one more decision ahead (Extreme).
static Level level_of(int level) {
	Level lv;
	switch(level) {
	case 1: lv = { 2, 6, 700, 2, 0.20, 31, 90.0, 1, 0.0, 2, 0 }; break;      // Normal
	case 2: lv = { 6, 10, 1600, 2, 0.0, 31, 90.0, 1, 60.0, 4, 0 }; break;    // Hard
	default: lv = { 12, 14, 3600, 2, 0.0, 31, 90.0, 1, 60.0, 4, 3 }; break;  // Extreme
	}
	// Dev: OCG_AI="worlds=4,cap=12,ms=3000,horizon=2,deal=31,bias=90,threads=1,deep=0" overrides, for tuning.
	if(const char* env = std::getenv("OCG_AI")) {
		std::string e(env);
		auto val = [&](const char* key, double d) { auto p = e.find(std::string(key) + "="); return p == std::string::npos ? d : std::atof(e.c_str() + p + std::strlen(key) + 1); };
		lv.worlds = (int)val("worlds", lv.worlds); lv.cap = (size_t)val("cap", (double)lv.cap); lv.ms = (int)val("ms", lv.ms);
		lv.horizon = (int)val("horizon", lv.horizon); lv.deal = (int)val("deal", lv.deal); lv.bias = val("bias", lv.bias);
		lv.mode = (int)val("mode", lv.mode); lv.margin = val("margin", lv.margin); lv.threads = (int)val("threads", lv.threads); lv.deep = (int)val("deep", lv.deep);
	}
	unsigned hw = std::thread::hardware_concurrency();
	if(hw >= 2) lv.threads = std::min<int>(lv.threads, (int)hw - 1);
	lv.threads = std::max(1, lv.threads);
	return lv;
}

struct Decision { std::vector<uint8_t> bytes; int sims = 0; int cands = 0; double ms = 0; std::string notes; };

static uint64_t mix(uint64_t x) { x += 0x9E3779B97F4A7C15ull; x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9ull; x = (x ^ (x >> 27)) * 0x94D049BB133111EBull; return x ^ (x >> 31); }

static void world_seed(uint64_t seed, int w, uint64_t out[4]) {
	out[0] = mix(seed + 77 * (uint64_t)w + 1); out[1] = mix(seed ^ (0xABCDEFull + w)); out[2] = mix(seed + 3 * (uint64_t)w); out[3] = mix(seed + 9);
}

// One try: the duel as it stands, your hidden cards re-dealt for world `w`, these answers given, then played out.
static double one_try(const History& h, const Level& lv, uint64_t seed, int w, int me, int until,
		const std::vector<std::vector<uint8_t>>& answers, std::vector<std::vector<uint8_t>>* record, std::unique_ptr<Sim>* keep) {
	uint64_t ws[4];
	world_seed(seed, w, ws);
	auto sim = sim_replay(h);
	if(!sim || !sim->has_ask) return 0.0;
	if(lv.deal) OCG_DuelDeterminize(sim->d.d, (uint8_t)(1 - me), ws, (uint32_t)lv.deal);
	for(auto& a : answers) {
		if(!sim->has_ask || sim->winner != -1) break;
		note_answer(*sim, sim->ask, a);
		OCG_DuelSetResponse(sim->d.d, a.data(), (uint32_t)a.size());
		sim_step(*sim);
		if(sim->retry) return -5e5;      // (not a legal answer after all)
	}
	uint64_t rnd = ws[0] | 1;
	if(record) {
		// Play on with the steady policy until it is `me` to choose between at least two things again.
		PMemo memo[2];
		for(int guard = 0; guard < 300; ++guard) {
			if(!sim->has_ask || sim->winner != -1 || sim->turns >= until) break;
			int p = (int)sim->ask.geti("p");
			if(p == me && candidates(*sim, sim->ask, 8).size() >= 2) { if(keep) *keep = std::move(sim); return 0.0; }
			if(p < 0 || p > 1) break;
			auto ans = policy(*sim, sim->ask, memo[p], sim->retry, rnd, lv.mode);
			record->push_back(ans);
			note_answer(*sim, sim->ask, ans);
			OCG_DuelSetResponse(sim->d.d, ans.data(), (uint32_t)ans.size());
			sim_step(*sim);
		}
		return 0.0;
	}
	return rollout(*sim, me, until, rnd, 1500, lv.mode).score;
}

static Decision decide(const History& h, int level, int time_ms, uint64_t seed, PMemo* lives = nullptr) {
	Decision out;
	auto t0 = std::chrono::steady_clock::now();
	auto elapsed = [&]() { return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count(); };
	auto root = sim_replay(h);
	uint64_t rnd = mix(seed) | 1;
	if(!root || !root->has_ask) { out.bytes = bytes_i32(0); return out; }
	const JV m = root->ask;
	int me = (int)m.geti("p");
	PMemo* live = (lives && me >= 0 && me < 2) ? &lives[me] : nullptr;   // what the steady policy remembers of this turn
	PMemo mm;
	if(live) mm = *live;
	if(root->retry || level <= 0) { out.bytes = policy(*root, m, mm, root->retry, rnd); if(live) *live = mm; out.ms = elapsed(); return out; }
	Level lv = level_of(level);
	if(time_ms > 0) { lv.ms = time_ms; lv.deep = 0; }
	std::vector<Cand> cands = candidates(*root, m, lv.cap);
	std::vector<uint8_t> base = policy(*root, m, mm, false, rnd, lv.mode);
	if(live) { live->fresh(root->turns, root->turn_player); live->acts++; }
	if(cands.size() <= 1) { out.bytes = cands.size() == 1 ? cands[0].bytes : base; if(live && out.bytes == base) *live = mm; out.ms = elapsed(); return out; }
	// The steady policy's own answer is tried first, so a short clock still has it.
	size_t base_i = cands.size();
	for(size_t i = 0; i < cands.size(); ++i) if(cands[i].bytes == base) base_i = i;
	if(base_i == cands.size()) cands.insert(cands.begin(), { base, "base" });
	else if(base_i != 0) std::swap(cands[0], cands[base_i]);
	out.cands = (int)cands.size();
	const int until = root->turns + lv.horizon;
	const size_t N = cands.size();
	const int W = lv.worlds;
	// score[w][c], filled world by world on a few threads. Only worlds that every answer was tried in count,
	// so every answer is judged on the same deals.
	std::vector<std::vector<double>> score(W, std::vector<double>(N, 0.0));
	std::vector<std::vector<char>> have(W, std::vector<char>(N, 0));
	std::atomic<size_t> next{ 0 };
	std::atomic<int> sims{ 0 };
	auto worker = [&]() {
		for(;;) {
			size_t j = next.fetch_add(1);
			if(j >= N * (size_t)W) break;
			int w = (int)(j / N); size_t c = j % N;
			if(w > 0 && elapsed() > lv.ms) break;
			if(w == 0 && c > 0 && elapsed() > lv.ms * 2.5) break;
			score[w][c] = one_try(h, lv, seed, w, me, until, { cands[c].bytes }, nullptr, nullptr);
			have[w][c] = 1;
			sims.fetch_add(1);
		}
	};
	{
		std::vector<std::thread> pool;
		for(int i = 1; i < lv.threads; ++i) pool.emplace_back(worker);
		worker();
		for(auto& t : pool) t.join();
	}
	std::vector<double> total(N, 0.0);
	std::vector<int> count(N, 0);
	int full = 0;
	for(int w = 0; w < W; ++w) {
		bool all = true;
		for(size_t c = 0; c < N; ++c) if(!have[w][c]) all = false;
		if(!all) continue;
		full++;
		for(size_t c = 0; c < N; ++c) { total[c] += score[w][c]; count[c]++; }
	}
	if(full == 0) for(size_t c = 0; c < N; ++c) if(have[0][c]) { total[c] = score[0][c]; count[c] = 1; }
	static const std::set<std::string> passive = { "ep", "bp", "m2", "pass", "n", "none", "done" };
	std::vector<double> value(N, -1e18);
	for(size_t c = 0; c < N; ++c)
		if(count[c]) value[c] = total[c] / count[c] + (passive.count(cands[c].key) ? 0.0 : lv.bias);
	// Between doing something and doing nothing that come out the same, it does something: what a
	// search or a set-up is worth does not show on the table yet (that is the small bias above).

	// Extreme: the best few answers get a second look. After each, what is the best thing to do next?
	int t = (int)m.geti("t");
	if(lv.deep > 0 && (t == 10 || t == 11) && elapsed() < lv.ms * 0.8) {
		std::vector<size_t> order;
		for(size_t c = 0; c < N; ++c) if(count[c]) order.push_back(c);
		std::sort(order.begin(), order.end(), [&](size_t a, size_t b) { return value[a] > value[b]; });
		order.resize(std::min<size_t>(order.size(), (size_t)lv.deep));
		const int W2 = std::min(3, std::max(1, full));
		for(size_t a : order) {
			if(passive.count(cands[a].key) && cands[a].key != "bp") continue;
			if(elapsed() > lv.ms * 1.6) break;
			std::vector<std::vector<uint8_t>> prefix = { cands[a].bytes };
			std::unique_ptr<Sim> at;
			one_try(h, lv, seed, 0, me, until, { cands[a].bytes }, &prefix, &at);
			if(!at) continue;
			std::vector<Cand> next_c = candidates(*at, at->ask, 7);
			at.reset();
			if(next_c.size() < 2) continue;
			double best2 = -1e18;
			for(auto& b2 : next_c) {
				if(elapsed() > lv.ms * 1.6) break;
				std::vector<std::vector<uint8_t>> line = prefix;
				line.push_back(b2.bytes);
				double sum = 0; int n = 0;
				for(int w = 0; w < W2; ++w) {
					// (the prefix was found in world 0; in another deal it may not fit, then that try is skipped)
					double sc = one_try(h, lv, seed, w, me, until, line, nullptr, nullptr);
					sims.fetch_add(1);
					if(sc <= -4e5 && w > 0) continue;
					sum += sc; n++;
				}
				if(n) best2 = std::max(best2, sum / n);
			}
			if(best2 > -1e17) value[a] = std::max(value[a], best2 + (passive.count(cands[a].key) ? 0.0 : lv.bias));
		}
	}
	out.sims = sims.load();
	size_t best = 0; double best_v = -1e18;
	std::vector<std::pair<double, size_t>> ranked;
	for(size_t c = 0; c < N; ++c) {
		if(!count[c]) continue;
		ranked.push_back({ value[c], c });
		if(value[c] > best_v) { best_v = value[c]; best = c; }
	}
	// Normal plays like a person: now and then it takes its second idea.
	if(lv.slip > 0 && ranked.size() >= 2) {
		std::sort(ranked.begin(), ranked.end(), [](auto& a, auto& b) { return a.first > b.first; });
		rnd = mix(rnd);
		if((rnd % 1000) / 1000.0 < lv.slip && ranked[0].first - ranked[1].first < 2500) best = ranked[1].second;
	}
	// The steady policy's answer stands unless another is better by a clear margin.
	if(best != 0 && count[0] > 0 && lv.margin > 0 && lv.slip <= 0 && best_v - value[0] < lv.margin) best = 0;
	if(live && best == 0) *live = mm;
	for(size_t c = 0; c < N; ++c)
		out.notes += (c == best ? "*" : " ") + cands[c].key + "=" + (count[c] ? std::to_string((long)value[c]) : "?") + "  ";
	out.notes += "[deals " + std::to_string(full) + "]";
	out.bytes = cands[best].bytes;
	out.ms = elapsed();
	return out;
}

// ---------------------------------------------------------------- a whole duel, both sides (for measuring)
struct MatchResult { int winner = 2; int turns = 0; long decisions = 0; long sims = 0; double think_ms = 0; double max_ms = 0; int refused = 0; Board end; };

static MatchResult play_match(History h, int level0, int level1, uint64_t seed, int time_ms, int max_turns) {
	MatchResult r;
	auto live = sim_new(h);
	if(!live) return r;
	sim_step(*live);
	PMemo memo[2];
	uint64_t rnd = mix(seed) | 1;
	int refused = 0, last_turn = -1, turn_decisions = 0;
	const bool trace = std::getenv("OCG_TRACE") != nullptr;
	std::string last_notes;
	while(live->winner == -1 && live->status == OCG_DUEL_STATUS_AWAITING && live->has_ask && live->turns <= max_turns) {
		int p = (int)live->ask.geti("p");
		if(p < 0 || p > 1) break;
		int lv = p == 0 ? level0 : level1;
		std::vector<uint8_t> ans;
		if(live->retry) {
			r.refused++;
			if(++refused > 8) break;
			ans = policy(*live, live->ask, memo[p], true, rnd);
		} else if(lv <= 0 || turn_decisions > 120) {
			ans = policy(*live, live->ask, memo[p], turn_decisions > 160, rnd);
		} else {
			Decision d = decide(h, lv, time_ms, mix(seed + r.decisions), memo);
			ans = d.bytes;
			last_notes = d.cands > 1 ? d.notes : "";
			r.sims += d.sims; r.think_ms += d.ms; r.max_ms = std::max(r.max_ms, d.ms);
		}
		if(trace && lv > 0 && !last_notes.empty()) fprintf(stderr, "T%d ask %d: %s\n", live->turns, (int)live->ask.geti("t"), last_notes.c_str());
		note_answer(*live, live->ask, ans);
		r.decisions++;
		if(live->turns != last_turn) { last_turn = live->turns; turn_decisions = 0; }
		turn_decisions++;
		h.answers.push_back(ans);
		OCG_DuelSetResponse(live->d.d, ans.data(), (uint32_t)ans.size());
		sim_step(*live);
	}
	r.winner = live->winner == -1 ? 2 : live->winner;
	r.turns = live->turns;
	r.end = read_board(*live);
	return r;
}
