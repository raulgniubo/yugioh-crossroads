--Echo Merge (a card of Crossroads)
local s,id=GetID()
local SET_LUMEN=0xfe0
function s.initial_effect(c)
	--Fusion Summon 1 "Lumen" Fusion Monster, using monsters from your hand or field as material.
	--If you use a "Lumen, Echo Spirit" you control as material, you can also use 1 monster from your Deck.
	local e1=Fusion.CreateSummonEff({handler=c,fusfilter=aux.FilterBoolFunction(Card.IsSetCard,SET_LUMEN),extrafil=s.fextra,extratg=s.extratg})
	c:RegisterEffect(e1)
end
s.listed_names={99200001}
s.listed_series={SET_LUMEN}
function s.spirit(c)
	return c:IsFaceup() and c:IsCode(99200001) and c:IsLocation(LOCATION_MZONE)
end
function s.fextra(e,tp,mg)
	if Duel.IsExistingMatchingCard(s.spirit,tp,LOCATION_MZONE,0,1,nil) then
		return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToGrave),tp,LOCATION_DECK,0,nil),s.fcheck
	end
	return nil
end
function s.fcheck(tp,sg,fc)
	local dc=sg:FilterCount(Card.IsLocation,nil,LOCATION_DECK)
	return dc==0 or (dc==1 and sg:IsExists(s.spirit,1,nil))
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_DECK)
end
