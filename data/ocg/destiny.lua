--Destiny Draw (a rule of Crossroads): once per duel, at 2000 Life Points or less, or with less
--than half of your opponent's, you choose the card your Draw Phase draws.
--CROSSROADS_DESTINY says which players may ({[0]=true,[1]=false}); the game sets it before this runs.
local who=CROSSROADS_DESTINY or {}
local used={[0]=false,[1]=false}
local e=Effect.GlobalEffect()
e:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
e:SetCode(EVENT_PREDRAW)
e:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetTurnPlayer()
	if not who[p] or used[p] then return false end
	if Duel.GetFieldGroupCount(p,LOCATION_DECK,0)==0 or Duel.GetDrawCount(p)==0 then return false end
	local lp=Duel.GetLP(p)
	return lp<=2000 or lp*2<Duel.GetLP(1-p)
end)
e:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetTurnPlayer()
	if not Duel.SelectYesNo(p,aux.Stringid(99199999,0)) then return end
	Duel.Hint(HINT_SELECTMSG,p,aux.Stringid(99199999,1))
	local g=Duel.SelectMatchingCard(p,aux.TRUE,p,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		used[p]=true
		Duel.ShuffleDeck(p)
		Duel.MoveSequence(tc,SEQ_DECKTOP)
	end
end)
Duel.RegisterEffect(e,0)
