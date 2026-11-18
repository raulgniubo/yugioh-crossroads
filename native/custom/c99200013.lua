--Echo Veil (a card of Crossroads)
local s,id=GetID()
function s.initial_effect(c)
	--When an opponent's monster declares an attack: negate the attack.
	--Then, if you control a "Lumen" monster, draw 1 card.
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_ATTACK_ANNOUNCE)
	e1:SetCondition(function(e,tp) return Duel.GetAttacker():IsControler(1-tp) end)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
local LUMEN={99200001,99200002,99200003,99200004,99200005}
function s.lfilter(c)
	return c:IsFaceup() and c:IsCode(table.unpack(LUMEN))
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateAttack() and Duel.IsExistingMatchingCard(s.lfilter,tp,LOCATION_MZONE,0,1,nil) then
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
