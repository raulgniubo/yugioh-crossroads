--Echo Bond (a card of Crossroads)
local s,id=GetID()
local SET_LUMEN=0xfe0
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--"Lumen" monsters you control gain 300 ATK, and 100 more for every bond you have made
	--(the game writes the number of bonds, 0 to 5, where a monster's ATK would be)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_SZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,SET_LUMEN))
	e1:SetValue(function(e) return 300+100*math.max(0,math.min(5,e:GetHandler():GetTextAttack())) end)
	c:RegisterEffect(e1)
	--Once per turn, if a "Lumen" monster you control is destroyed: you can return it to your hand (or Extra Deck)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(function(e,tp,eg) return eg:IsExists(s.cfilter,1,nil,tp) end)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_LUMEN}
function s.cfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE) and c:IsPreviousPosition(POS_FACEUP)
		and c:IsSetCard(SET_LUMEN) and c:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED) and c:IsFaceup()
		and (c:IsAbleToHand() or c:IsAbleToExtra())
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.cfilter,nil,tp)
	if chk==0 then return #g>0 end
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end
	if #g>1 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		g=g:Select(tp,1,1,nil)
	end
	Duel.SendtoHand(g,nil,REASON_EFFECT)
end
