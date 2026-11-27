--Echo Dawn Rite (a card of Crossroads)
local s,id=GetID()
function s.initial_effect(c)
	--Ritual Summon "Lumen, Echo Aurora": Tribute monsters from your hand or field whose total
	--Levels equal 8 or more ("Lumen, Echo Spirit" can be the entire Tribute: see her own script)
	Ritual.AddProcGreaterCode(c,8,nil,99200006)
end
s.listed_names={99200006,99200001}
