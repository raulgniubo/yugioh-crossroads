--Speed Spell - Chequered Flag (a card of Crossroads; Turbo Duels)
local s,id=GetID()
s.speed_need=10
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(function(e,tp) return Speed and Speed.Get(tp)>=s.speed_need end)
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_DAMAGE)
	e1:SetCost(s.cost)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
--Spend 8 Speed Counters: draw 2 cards, then inflict 1000 damage to your opponent
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Speed.Get(tp)>=8 end
	Speed.Pay(tp,8)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,2,REASON_EFFECT)
	Duel.BreakEffect()
	Duel.Damage(1-tp,1000,REASON_EFFECT)
end
