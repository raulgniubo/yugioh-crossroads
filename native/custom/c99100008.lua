--Speed Spell - Overtake (a card of Crossroads; Turbo Duels)
local s,id=GetID()
s.speed_need=6
function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(function(e,tp) return Speed and Speed.Get(tp)>=s.speed_need end)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetCost(s.cost)
	e1:SetTarget(s.tg)
	e1:SetOperation(s.op)
	c:RegisterEffect(e1)
end
--Spend 3 Speed Counters: destroy the monster your opponent controls with the highest DEF
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Speed.Get(tp)>=3 end
	Speed.Pay(tp,3)
end
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_MZONE)
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
	if #g==0 then return end
	local tg=g:GetMaxGroup(Card.GetDefense)
	if #tg>1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		tg=tg:Select(tp,1,1,nil)
	end
	Duel.Destroy(tg,REASON_EFFECT)
end
