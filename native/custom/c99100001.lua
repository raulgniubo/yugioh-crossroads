--Speed Spell - Full Throttle (a card of Crossroads; Turbo Duels)
local s,id=GetID()
s.speed_need=0
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(function(e,tp) return Speed and Speed.Get(tp)>=s.speed_need end)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
--Gain 2 Speed Counters
function s.op(e,tp,eg,ep,ev,re,r,rp)
	Speed.Add(tp,2)
end
