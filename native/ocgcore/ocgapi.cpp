/*
 * Copyright (c) 2019, Dylam De La Torre, (DyXel)
 * Copyright (c) 2019-2025, Edoardo Lolletti (edo9300) <edoardo762@gmail.com>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */
#include <cstring> //std::memcpy
#include <new> //std::nothrow
#include <vector>
#include "ocgapi.h"
#include "interpreter.h"
#include "duel.h"
#include "field.h"
#include "effect.h"

void OCG_GetVersion(int* major, int* minor) {
	if(major)
		*major = OCG_VERSION_MAJOR;
	if(minor)
		*minor = OCG_VERSION_MINOR;
}

int OCG_CreateDuel(OCG_Duel* out_ocg_duel, const OCG_DuelOptions* options_ptr) {
	if(out_ocg_duel == nullptr)
		return OCG_DUEL_CREATION_NO_OUTPUT;
	auto options = *options_ptr;
	if(options.cardReader == nullptr) {
		*out_ocg_duel = nullptr;
		return OCG_DUEL_CREATION_NULL_DATA_READER;
	}
	if(options.scriptReader == nullptr) {
		*out_ocg_duel = nullptr;
		return OCG_DUEL_CREATION_NULL_SCRIPT_READER;
	}
	if(options.logHandler == nullptr) {
		options.logHandler = [](void* /*payload*/, const char* /*string*/, int /*type*/) {};
		options.payload3 = nullptr;
	}
	if(options.cardReaderDone == nullptr) {
		options.cardReaderDone = [](void* /*payload*/, OCG_CardData* /*data*/) {};
		options.payload4 = nullptr;
	}
	if(options.seed[0] == 0 && options.seed[1] == 0 && options.seed[2] == 0 && options.seed[3] == 0)
		return OCG_DUEL_CREATION_NULL_RNG_SEED;
	bool valid_lua_lib = true;
	auto* duelPtr = new (std::nothrow) duel(options, valid_lua_lib);
	if(duelPtr == nullptr)
		return OCG_DUEL_CREATION_NOT_CREATED;
	if(!valid_lua_lib) {
		delete duelPtr;
		return OCG_DUEL_CREATION_INCOMPATIBLE_LUA_API;
	}
	*out_ocg_duel = static_cast<OCG_Duel>(duelPtr);
	return OCG_DUEL_CREATION_SUCCESS;
}

void OCG_DestroyDuel(OCG_Duel ocg_duel) {
	if(ocg_duel)
		delete static_cast<duel*>(ocg_duel);
}

void OCG_DuelNewCard(OCG_Duel ocg_duel, const OCG_NewCardInfo* info_ptr) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	auto& game_field = *(pduel->game_field);
	const auto& info = *info_ptr;
	if(bit::popcnt(info.loc) > 1)
		return;
	auto duelist = info.duelist;
	if(duelist == 0) {
		if(game_field.is_location_useable(info.con, info.loc, info.seq)) {
			card* pcard = pduel->new_card(info.code);
			pcard->owner = info.team;
			game_field.add_card(info.con, pcard, (uint8_t)info.loc, (uint8_t)info.seq);
			pcard->current.position = info.pos;
			if(!(info.loc & LOCATION_ONFIELD) || (info.pos & POS_FACEUP)) {
				pcard->enable_field_effect(true);
				game_field.adjust_instant();
			}
			if(info.loc & LOCATION_ONFIELD) {
				if(info.loc == LOCATION_MZONE)
					pcard->set_status(STATUS_PROC_COMPLETE, TRUE);
			}
		}
	} else {
		if(info.team > 1 || !(info.loc & (LOCATION_DECK | LOCATION_EXTRA)))
			return;
		card* pcard = pduel->new_card(info.code);
		auto& player = game_field.player[info.team];
		if(duelist > player.extra_lists_main.size()) {
			player.extra_lists_main.resize(duelist);
			player.extra_lists_extra.resize(duelist);
			player.extra_lists_hand.resize(duelist);
			player.extra_extra_p_count.resize(duelist);
		}
		--duelist;
		pcard->current.location = static_cast<uint8_t>(info.loc);
		pcard->owner = info.team;
		pcard->current.controler = info.team;
		pcard->current.position = POS_FACEDOWN_DEFENSE;
		auto& list = (info.loc == LOCATION_DECK) ? player.extra_lists_main[duelist] : player.extra_lists_extra[duelist];
		list.push_back(pcard);
		pcard->current.sequence = static_cast<uint32_t>(list.size() - 1);
	}
}

void OCG_StartDuel(OCG_Duel ocg_duel) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	pduel->game_field->emplace_process<Processors::Startup>();
}

int OCG_DuelProcess(OCG_Duel ocg_duel) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	pduel->buff.clear();
	auto flag = OCG_DUEL_STATUS_END;
	do {
		flag = pduel->game_field->process();
		pduel->generate_buffer();
	} while(pduel->buff.size() == 0 && flag == OCG_DUEL_STATUS_CONTINUE);
	return flag;
}

void* OCG_DuelGetMessage(OCG_Duel ocg_duel, uint32_t* length) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	pduel->generate_buffer();
	if(length)
		*length = static_cast<uint32_t>(pduel->buff.size());
	return pduel->buff.data();
}

void OCG_DuelSetResponse(OCG_Duel ocg_duel, const void* buffer, uint32_t length) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	pduel->set_response(buffer, length);
}

int OCG_LoadScript(OCG_Duel ocg_duel, const char* buffer, uint32_t length, const char* name) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	return pduel->lua->load_script(buffer, length, name);
}

uint32_t OCG_DuelQueryCount(OCG_Duel ocg_duel, uint8_t team, uint32_t loc) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	if(team > 1)
		return 0;
	if(bit::popcnt(loc) != 1)
		return 0;
	auto& player = pduel->game_field->player[team];
	if(loc == LOCATION_HAND)
		return static_cast<uint32_t>(player.list_hand.size());
	if(loc == LOCATION_GRAVE)
		return static_cast<uint32_t>(player.list_grave.size());
	if (loc == LOCATION_REMOVED)
		return static_cast<uint32_t>(player.list_remove.size());
	if (loc == LOCATION_EXTRA)
		return static_cast<uint32_t>(player.list_extra.size());
	if (loc == LOCATION_DECK)
		return static_cast<uint32_t>(player.list_main.size());
	uint32_t count = 0;
	if(loc == LOCATION_MZONE) {
		for(auto& pcard : player.list_mzone)
			if(pcard) ++count;
	}
	if(loc == LOCATION_SZONE) {
		for(auto& pcard : player.list_szone)
			if(pcard) ++count;
	}
	return count;
}
template<typename T>
void insert_value_int(std::vector<uint8_t>& vec, T val) {
	const auto vec_size = vec.size();
	const auto val_size = sizeof(T);
	vec.resize(vec_size + val_size);
	std::memcpy(&vec[vec_size], &val, val_size);
}
template<typename T, typename T2>
ForceInline void insert_value(std::vector<uint8_t>& vec, T2 val) {
	insert_value_int<T>(vec, static_cast<T>(val));
}

void* OCG_DuelQuery(OCG_Duel ocg_duel, uint32_t* length, const OCG_QueryInfo* info_ptr) {
	const auto& info = *info_ptr;
	auto* pduel = static_cast<duel*>(ocg_duel);
	if(bit::popcnt(info.loc & ~LOCATION_OVERLAY) != 1)
		return nullptr;
	pduel->query_buffer.clear();
	card* pcard = nullptr;
	if(info.loc & LOCATION_OVERLAY) {
		auto olcard = pduel->game_field->get_field_card(info.con, (info.loc & LOCATION_OVERLAY), info.seq);
		if(olcard && olcard->xyz_materials.size() > info.overlay_seq) {
			pcard = olcard->xyz_materials[info.overlay_seq];
		}
	} else {
		pcard = pduel->game_field->get_field_card(info.con, info.loc, info.seq);
	}
	if(pcard == nullptr) {
		if(length)
			*length = 0;
		return nullptr;
	} else {
		pcard->get_infos(info.flags);
	}
	if(length)
		*length = static_cast<uint32_t>(pduel->query_buffer.size());
	return pduel->query_buffer.data();
}

void* OCG_DuelQueryLocation(OCG_Duel ocg_duel, uint32_t* length, const OCG_QueryInfo* info_ptr) {
	const auto& info = *info_ptr;
	auto* pduel = static_cast<duel*>(ocg_duel);
	auto& buffer = pduel->query_buffer;
	auto populate = [&flags = info.flags, &buffer](const card_vector& list) {
		for(auto& pcard : list) {
			if(pcard == nullptr) {
				insert_value<int16_t>(buffer, 0);
			} else {
				pcard->get_infos(flags);
			}
		}
	};
	buffer.clear();
	if(info.con <= 1u && bit::popcnt(info.loc & ~LOCATION_OVERLAY) == 1) {
		if(info.loc & LOCATION_OVERLAY) {
			insert_value<int16_t>(buffer, 0);
		} else {
			auto& player = pduel->game_field->player[info.con];
			if(info.loc == LOCATION_MZONE)
				populate(player.list_mzone);
			else if(info.loc == LOCATION_SZONE)
				populate(player.list_szone);
			else if(info.loc == LOCATION_HAND)
				populate(player.list_hand);
			else if(info.loc == LOCATION_GRAVE)
				populate(player.list_grave);
			else if(info.loc == LOCATION_REMOVED)
				populate(player.list_remove);
			else if(info.loc == LOCATION_EXTRA)
				populate(player.list_extra);
			else if(info.loc == LOCATION_DECK)
				populate(player.list_main);
		}
		std::vector<uint8_t> tmp_vector;
		insert_value<uint32_t>(tmp_vector, buffer.size());
		buffer.insert(buffer.begin(), tmp_vector.begin(), tmp_vector.end());
	}
	if(length)
		*length = static_cast<uint32_t>(buffer.size());
	return buffer.data();
}

void* OCG_DuelQueryField(OCG_Duel ocg_duel, uint32_t* length) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	auto& query = pduel->query_buffer;
	query.clear();
	//insert_value<int8_t>(query, MSG_RELOAD_FIELD);
	insert_value<uint32_t>(query, pduel->game_field->core.duel_options);
	for(int playerid = 0; playerid < 2; ++playerid) {
		auto& player = pduel->game_field->player[playerid];
		insert_value<uint32_t>(query, player.lp);
		for(auto& pcard : player.list_mzone) {
			if(pcard) {
				insert_value<uint8_t>(query, 1);
				insert_value<uint8_t>(query, pcard->current.position);
				insert_value<uint32_t>(query, pcard->xyz_materials.size());
			} else {
				insert_value<uint8_t>(query, 0);
			}
		}
		for(auto& pcard : player.list_szone) {
			if(pcard) {
				insert_value<uint8_t>(query, 1);
				insert_value<uint8_t>(query, pcard->current.position);
				insert_value<uint32_t>(query, pcard->xyz_materials.size());
			} else {
				insert_value<uint8_t>(query, 0);
			}
		}
		insert_value<uint32_t>(query, player.list_main.size());
		insert_value<uint32_t>(query, player.list_hand.size());
		insert_value<uint32_t>(query, player.list_grave.size());
		insert_value<uint32_t>(query, player.list_remove.size());
		insert_value<uint32_t>(query, player.list_extra.size());
		insert_value<uint32_t>(query, player.extra_p_count);
	}
	insert_value<uint32_t>(query, pduel->game_field->core.current_chain.size());
	for(const auto& ch : pduel->game_field->core.current_chain) {
		effect* peffect = ch.triggering_effect;
		insert_value<uint32_t>(query, peffect->get_handler()->data.code);
		loc_info info = peffect->get_handler()->get_info_location();
		insert_value<uint8_t>(query, info.controler);
		insert_value<uint8_t>(query, info.location);
		insert_value<uint32_t>(query, info.sequence);
		insert_value<uint32_t>(query, info.position);
		insert_value<uint8_t>(query, ch.triggering_controler);
		insert_value<uint8_t>(query, static_cast<uint8_t>(ch.triggering_location));
		insert_value<uint32_t>(query, ch.triggering_sequence);
		insert_value<uint64_t>(query, peffect->description);
	}
	if(length)
		*length = static_cast<uint32_t>(query.size());
	return query.data();
}


/*** CROSSROADS ADDITION (not part of upstream ocgcore) ***/
namespace {
struct XorShift {
	uint64_t s;
	uint64_t next() { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s; }
	uint32_t below(uint32_t n) { return n ? static_cast<uint32_t>(next() % n) : 0; }
};
struct Place {
	uint8_t controler, location, sequence;
	uint32_t position;
	bool pzone;
	uint32_t status;
	uint16_t turnid;
	uint32_t fieldid, fieldid_r;
	card::summon_info summon;
	uint32_t reason;
	uint8_t reason_player;
	card* reason_card;
	effect* reason_effect;
	uint8_t p_controler, p_location;
	uint32_t p_sequence, p_position, p_reason;
	bool p_pzone;
};
Place place_of(card* c) {
	return { c->current.controler, c->current.location, static_cast<uint8_t>(c->current.sequence), c->current.position, c->current.pzone,
		c->status, c->turnid, c->fieldid, c->fieldid_r, c->summon, c->current.reason, c->current.reason_player, c->current.reason_card,
		c->current.reason_effect, c->previous.controler, c->previous.location, c->previous.sequence, c->previous.position,
		c->previous.reason, c->previous.pzone };
}
void seat(field& f, card* c, const Place& p) {
	c->sendto_param.position = static_cast<uint8_t>(p.position);
	f.add_card(p.controler, c, p.location, (p.location == LOCATION_DECK) ? 0 : p.sequence, p.pzone);
	c->current.position = p.position;
	c->status = p.status;
	c->turnid = p.turnid;
	c->fieldid = p.fieldid;
	c->fieldid_r = p.fieldid_r;
	c->summon = p.summon;
	c->current.reason = p.reason;
	c->current.reason_player = p.reason_player;
	c->current.reason_card = p.reason_card;
	c->current.reason_effect = p.reason_effect;
	c->previous.controler = p.p_controler;
	c->previous.location = p.p_location;
	c->previous.sequence = p.p_sequence;
	c->previous.position = p.p_position;
	c->previous.reason = p.p_reason;
	c->previous.pzone = p.p_pzone;
}
/* 0 anything, 1 a monster, 2 a Spell/Trap (what kind of card may sit in that place) */
bool fits(card* c, int kind) {
	if(kind == 1) return (c->data.type & TYPE_MONSTER) != 0;
	if(kind == 2) return (c->data.type & (TYPE_SPELL | TYPE_TRAP)) != 0 && !(c->data.type & TYPE_FIELD);
	return true;
}
}

void OCG_DuelDeterminize(OCG_Duel ocg_duel, uint8_t team, const uint64_t* seed, uint32_t flags) {
	auto* pduel = static_cast<duel*>(ocg_duel);
	if(team > 1 || !seed)
		return;
	auto& f = *pduel->game_field;
	XorShift rng{ seed[0] ^ 0x9E3779B97F4A7C15ull };
	if(rng.s == 0)
		rng.s = 0x1234567ull;
	auto& pl = f.player[team];
	const bool saved_check = f.core.shuffle_check_disabled;
	f.core.shuffle_check_disabled = true;
	const auto saved_sent = f.core.just_sent_cards;
	/* every hidden card of that player, and the kind of card its place asks for */
	std::vector<card*> cards;
	std::vector<int> kinds;
	std::vector<size_t> targets;
	auto hidden = [team](card* c) {
		return c && c->owner == team && c->current.controler == team && !c->overlay_target && !c->equiping_target
			&& c->xyz_materials.empty() && c->counters.empty();
	};
	/* CROSSROADS (0.85.0), flag 32: a hand card the other side has seen stays where it is: one that
	   came back from the field, the Graveyard or the banished pile, or was added from the Deck by an
	   effect other than a draw (a search shows the card). */
	auto seen = [](card* c) {
		if(c->previous.location & (LOCATION_MZONE | LOCATION_SZONE | LOCATION_GRAVE | LOCATION_REMOVED))
			return (c->previous.position & POS_FACEUP) != 0 || (c->previous.location & (LOCATION_GRAVE | LOCATION_REMOVED)) != 0;
		if((c->previous.location & LOCATION_DECK) && (c->current.reason & REASON_EFFECT) && !(c->current.reason & REASON_DRAW))
			return true;
		return false;
	};
	for(auto* c : pl.list_hand) {
		if((flags & 32) && seen(c))
			continue;
		if(hidden(c) && !(c->current.position & POS_FACEUP) && !c->is_affected_by_effect(EFFECT_PUBLIC)) {
			if(flags & 1) targets.push_back(cards.size());
			cards.push_back(c); kinds.push_back(0);
		}
	}
	if(flags & 2) {
		for(size_t i = 0; i < 5 && i < pl.list_mzone.size(); ++i) {
			auto* c = pl.list_mzone[i];
			if(hidden(c) && (c->current.position & POS_FACEDOWN) && !(c->previous.position & POS_FACEUP)
				&& (c->previous.location & (LOCATION_HAND | LOCATION_DECK)) && (c->data.type & TYPE_MONSTER)) {
				targets.push_back(cards.size());
				cards.push_back(c); kinds.push_back(1);
			}
		}
	}
	if(flags & 4) {
		for(size_t i = 0; i < 5 && i < pl.list_szone.size(); ++i) {
			auto* c = pl.list_szone[i];
			if(hidden(c) && (c->current.position & POS_FACEDOWN) && !(c->previous.position & POS_FACEUP)
				&& (c->previous.location & (LOCATION_HAND | LOCATION_DECK)) && fits(c, 2)) {
				targets.push_back(cards.size());
				cards.push_back(c); kinds.push_back(2);
			}
		}
	}
	if(!targets.empty()) {
		for(auto* c : pl.list_main) {
			if(hidden(c)) { cards.push_back(c); kinds.push_back(0); }
		}
		for(int pass = 0; pass < 2; ++pass) {
			for(size_t t : targets) {
				size_t j = rng.below(static_cast<uint32_t>(cards.size()));
				if(j == t || cards[j] == cards[t])
					continue;
				card* a = cards[t];
				card* b = cards[j];
				if(!fits(b, kinds[t]) || !fits(a, kinds[j]))
					continue;
				if(a->current.location == LOCATION_DECK && b->current.location == LOCATION_DECK)
					continue;
				const Place pa = place_of(a);
				const Place pb = place_of(b);
				f.remove_card(a);
				f.remove_card(b);
				seat(f, b, pa);
				seat(f, a, pb);
				if(a->current.location == 0 || b->current.location == 0) {
					/* a place refused its new card: put both back where they were */
					if(a->current.location) f.remove_card(a);
					if(b->current.location) f.remove_card(b);
					seat(f, a, pa);
					seat(f, b, pb);
					continue;
				}
				cards[t] = b;
				cards[j] = a;
			}
		}
	}
	if(flags & 8) {
		for(int p = 0; p < 2; ++p) {
			auto& deck = f.player[p].list_main;
			for(size_t i = deck.size(); i > 1; --i)
				std::swap(deck[i - 1], deck[rng.below(static_cast<uint32_t>(i))]);
			f.reset_sequence(static_cast<uint8_t>(p), LOCATION_DECK);
		}
	}
	if(flags & 16) {
		const uint64_t fresh[4] = { seed[0] | 1, seed[1] ^ rng.next(), seed[2] ^ rng.next(), seed[3] ^ rng.next() };
		pduel->reseed(fresh);
	}
	f.core.just_sent_cards = saved_sent;
	f.core.shuffle_check_disabled = saved_check;
}
