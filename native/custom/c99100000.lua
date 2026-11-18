--Speed World 2 (the road of every Turbo Duel in Crossroads; each rider has one in the Field Zone)
local s,id=GetID()
local COUNTER_SPEED=0x1091
Speed={}
--How many Speed Counters a rider has
function Speed.Get(tp)
	local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
	if fc and fc:IsCode(99100000) then return fc:GetCounter(COUNTER_SPEED) end
	return 0
end
function Speed.Add(tp,n)
	local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
	if not (fc and fc:IsCode(99100000)) then return end
	n=math.min(n,12-fc:GetCounter(COUNTER_SPEED))
	if n>0 then fc:AddCounter(COUNTER_SPEED,n) end
end
function Speed.Pay(tp,n,reason)
	local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
	if not (fc and fc:IsCode(99100000)) then return end
	n=math.min(n,fc:GetCounter(COUNTER_SPEED))
	if n>0 then fc:RemoveCounter(tp,COUNTER_SPEED,n,reason or REASON_COST) end
end
--Spells that ask for 2 more Speed Counters than the others
local HEAVY={[12580477]=true,[53129443]=true,[83764718]=true,[55144522]=true,[19613556]=true,
	[18144506]=true,[4031928]=true,[79571449]=true,[69162969]=true,[72892473]=true}
function Speed.Need(rc)
	if rc.speed_need then return rc.speed_need end
	local n=3
	if rc:IsType(TYPE_QUICKPLAY) or rc:IsType(TYPE_EQUIP) then n=2 end
	if HEAVY[rc:GetOriginalCode()] then n=n+2 end
	return n
end
--A Grand Prix lap or a tuned runner starts with Speed Counters already on the dial
--(CROSSROADS_SPEED_START={[0]=n,[1]=n}, set by the game before the duel starts).
if CROSSROADS_SPEED_START and not Speed.started then
	Speed.started=true
	local ge=Effect.GlobalEffect()
	ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge:SetCode(EVENT_STARTUP)
	ge:SetOperation(function()
		for p=0,1 do
			local n=CROSSROADS_SPEED_START[p] or 0
			if n>0 then Speed.Add(p,n) end
		end
	end)
	Duel.RegisterEffect(ge,0)
end
function s.initial_effect(c)
	c:EnableCounterPermit(COUNTER_SPEED)
	c:SetCounterLimit(COUNTER_SPEED,12)
	--It is the road itself: nothing takes it away or touches it
	for _,code in ipairs({EFFECT_INDESTRUCTABLE,EFFECT_CANNOT_REMOVE,EFFECT_CANNOT_TO_HAND,EFFECT_CANNOT_TO_DECK,EFFECT_CANNOT_TO_GRAVE,EFFECT_CANNOT_BE_EFFECT_TARGET}) do
		local e0=Effect.CreateEffect(c)
		e0:SetType(EFFECT_TYPE_SINGLE)
		e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
		e0:SetRange(LOCATION_FZONE)
		e0:SetCode(code)
		e0:SetValue(1)
		c:RegisterEffect(e0)
	end
	local ei=Effect.CreateEffect(c)
	ei:SetType(EFFECT_TYPE_SINGLE)
	ei:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	ei:SetRange(LOCATION_FZONE)
	ei:SetCode(EFFECT_IMMUNE_EFFECT)
	ei:SetValue(function(e,te) return te:GetOwner()~=e:GetOwner() end)
	c:RegisterEffect(ei)
	--Each Standby Phase after the first turn: 1 Speed Counter. Behind by 2000 or more Life Points: 1 more.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EVENT_PHASE_START+PHASE_STANDBY)
	e1:SetRange(LOCATION_FZONE)
	e1:SetCondition(function(e) return Duel.GetTurnCount()>1 end)
	e1:SetOperation(s.gain)
	c:RegisterEffect(e1)
	--Take 1000 or more damage at once: lose 1 Speed Counter for each 1000
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCode(EVENT_DAMAGE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetCondition(function(e,tp,eg,ep,ev) return ep==e:GetHandlerPlayer() and ev>=1000 end)
	e2:SetOperation(function(e,tp,eg,ep,ev) Speed.Pay(e:GetHandlerPlayer(),ev//1000,REASON_RULE) end)
	c:RegisterEffect(e2)
	--Spells need speed, and no other Field Spell takes the road
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(1,0)
	e3:SetValue(s.gate)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e4:SetCode(EFFECT_CANNOT_SSET)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(LOCATION_HAND,0)
	e4:SetTarget(function(e,c) return c:IsType(TYPE_FIELD) end)
	c:RegisterEffect(e4)
	--Once per turn, one of: 4 counters: 800 damage for each Spell in your hand. 7: draw 1. 10: destroy 1 card.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_DAMAGE)
	e5:SetType(EFFECT_TYPE_IGNITION)
	e5:SetRange(LOCATION_FZONE)
	e5:SetCountLimit(1,id)
	e5:SetCost(s.cost(4))
	e5:SetTarget(s.burntg)
	e5:SetOperation(s.burnop)
	c:RegisterEffect(e5)
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_DRAW)
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_FZONE)
	e6:SetCountLimit(1,id)
	e6:SetCost(s.cost(7))
	e6:SetTarget(s.drawtg)
	e6:SetOperation(s.drawop)
	c:RegisterEffect(e6)
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,2))
	e7:SetCategory(CATEGORY_DESTROY)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_FZONE)
	e7:SetCountLimit(1,id)
	e7:SetCost(s.cost(10))
	e7:SetTarget(s.destg)
	e7:SetOperation(s.desop)
	c:RegisterEffect(e7)
end
function s.gain(e,tp,eg,ep,ev,re,r,rp)
	local p=e:GetHandlerPlayer()
	local n=1
	if Duel.GetLP(p)<=Duel.GetLP(1-p)-2000 then n=2 end
	Speed.Add(p,n)
end
function s.gate(e,re,tp)
	if not re:IsHasType(EFFECT_TYPE_ACTIVATE) or not re:IsActiveType(TYPE_SPELL) then return false end
	local rc=re:GetHandler()
	if rc:IsType(TYPE_FIELD) then return true end
	return e:GetHandler():GetCounter(COUNTER_SPEED)<Speed.Need(rc)
end
function s.cost(n)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		local c=e:GetHandler()
		if chk==0 then return c:IsCanRemoveCounter(tp,COUNTER_SPEED,n,REASON_COST) end
		c:RemoveCounter(tp,COUNTER_SPEED,n,REASON_COST)
	end
end
function s.spellfilter(c)
	return c:IsSpell()
end
function s.burntg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spellfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,800)
end
function s.burnop(e,tp,eg,ep,ev,re,r,rp)
	local n=Duel.GetMatchingGroupCount(s.spellfilter,tp,LOCATION_HAND,0,nil)
	if n>0 then Duel.Damage(1-tp,800*n,REASON_EFFECT) end
end
function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end
function s.desfilter(c)
	return not c:IsCode(99100000)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
