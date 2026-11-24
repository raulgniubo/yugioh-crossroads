--Speed Spell - Rev Limiter (a card of Crossroads; Turbo Duels)
local s,id=GetID()
s.speed_need=6
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(function(e,tp) return Speed and Speed.Get(tp)>=s.speed_need end)
	e1:SetCost(s.cost)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
--Spend 2 Speed Counters: your opponent loses 4 Speed Counters
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Speed.Get(tp)>=2 end
	Speed.Pay(tp,2)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Speed.Get(1-tp)>0 end
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	Speed.Pay(1-tp,4,REASON_EFFECT)
end
