--Hall of Echoes (a card of Crossroads)
local s,id=GetID()
local SET_LUMEN=0xfe0
function s.initial_effect(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
	--LIGHT Fairy monsters you control gain 300 ATK
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_FZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_FAIRY) end)
	e1:SetValue(300)
	c:RegisterEffect(e1)
	--During your Main Phase, you can Normal Summon 1 "Lumen" monster in addition to your Normal Summon/Set
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_HAND|LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,SET_LUMEN))
	c:RegisterEffect(e2)
	--During your End Phase, if you control a "Lumen" monster: gain 500 Life Points
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_RECOVER)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EVENT_PHASE+PHASE_END)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.reccon)
	e3:SetTarget(s.rectg)
	e3:SetOperation(s.recop)
	c:RegisterEffect(e3)
end
s.listed_series={SET_LUMEN}
function s.reccon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(tp)
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,SET_LUMEN),tp,LOCATION_MZONE,0,1,nil)
end
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(500)
	Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500)
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Recover(p,d,REASON_EFFECT)
end
