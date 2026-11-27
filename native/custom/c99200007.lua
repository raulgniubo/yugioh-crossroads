--Lumen, Echo Nova (a card of Crossroads)
local s,id=GetID()
local SET_LUMEN=0xfe0
function s.initial_effect(c)
	c:EnableReviveLimit()
	--1 "Lumen" monster + 1 Fusion, Synchro or Xyz Monster
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_LUMEN),s.matfilter)
	--Gains 400 ATK for each kind of monster in your Graveyard among Ritual, Fusion, Synchro and Xyz
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(function(e,c) return s.kinds(c:GetControler())*400 end)
	c:RegisterEffect(e1)
	--Fusion Summoned: you can target up to that many cards your opponent controls; destroy them
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_LUMEN}
function s.matfilter(c,fc,sumtype,tp)
	return c:IsType(TYPE_FUSION|TYPE_SYNCHRO|TYPE_XYZ,fc,sumtype,tp)
end
function s.kfilter(c,t)
	return c:IsMonster() and c:IsType(t)
end
function s.kinds(tp)
	local n=0
	for _,t in ipairs({TYPE_RITUAL,TYPE_FUSION,TYPE_SYNCHRO,TYPE_XYZ}) do
		if Duel.IsExistingMatchingCard(s.kfilter,tp,LOCATION_GRAVE,0,1,nil,t) then n=n+1 end
	end
	return n
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	local n=s.kinds(tp)
	if chk==0 then return n>0 and Duel.IsExistingTarget(nil,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_ONFIELD,1,n,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
