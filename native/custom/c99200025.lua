--Echo Sentinel (a card of Crossroads)
local s,id=GetID()
local SET_LUMEN=0xfe0
local SET_ECHO=0xfe1
function s.initial_effect(c)
	--You can Special Summon this card (from your hand) by Tributing 1 "Echo" monster you control
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Your opponent cannot target "Lumen" monsters you control with card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(function(e,c) return c:IsFaceup() and c:IsSetCard(SET_LUMEN) end)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.CheckReleaseGroup(tp,Card.IsSetCard,1,false,1,true,c,tp,nil,false,nil,SET_ECHO)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.SelectReleaseGroup(tp,Card.IsSetCard,1,1,false,true,true,c,nil,nil,false,nil,SET_ECHO)
	if g and #g>0 then
		e:SetLabelObject(g)
		return true
	end
	return false
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if g and #g>0 then
		Duel.Release(g,REASON_COST)
	end
end
