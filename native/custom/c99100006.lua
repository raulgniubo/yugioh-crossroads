--Speed Spell - Afterburner (a card of Crossroads; Turbo Duels)
local s,id=GetID()
s.speed_need=4
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(function(e,tp) return Speed and Speed.Get(tp)>=s.speed_need end)
	e1:SetCategory(CATEGORY_DAMAGE)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
--Inflict 800 damage to your opponent
function s.op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Damage(1-tp,800,REASON_EFFECT)
end
