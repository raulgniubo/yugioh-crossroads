--Speed Spell - Pit Stop (a card of Crossroads; Turbo Duels)
local s,id=GetID()
s.speed_need=2
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(function(e,tp) return Speed and Speed.Get(tp)>=s.speed_need end)
	e1:SetCategory(CATEGORY_RECOVER)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
--Gain 1200 Life Points
function s.op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Recover(tp,1200,REASON_EFFECT)
end
