function SlashModules.PillAbility(ply, id, force)
    local pill = ply.pk_pill_ent

    if !IsValid(pill) then return end

    local pillForm = pill:GetPillForm()
    local pillTbl = pill.formTable
	
	if isstring(id) then
		for k, v in ipairs(pillTbl.abilities or {}) do
			if v.name != id then continue end

			id = k
			break
		end
	end

    if !pillTbl.abilities or !pillTbl.abilities[id] then return end
	ply.abilityCDs = ply.abilityCDs or {}

	if !force and ply.abilityCDs[id] and ((ply.abilityCDs[id].time + ply.abilityCDs[id].cooldown) > CurTime() or ply.abilityCDs[id].disabled) then return end
	
	local suc = true
	if pillTbl.abilities[id].func then
		local result = pillTbl.abilities[id].func(ply, pill)
		
		if isnumber(result) or result == false then
			suc = result
		end
	end

	if suc then
		local cd = isnumber(suc) and suc or pillTbl.abilities[id].cooldown
		
		ply.abilityCDs[id] = ply.abilityCDs[id] or {}

		ply.abilityCDs[id].time = CurTime()
		ply.abilityCDs[id].cooldown = cd
	end

	net.Start("SlashModules.PillBind")
	net.WriteTable(ply.abilityCDs)
	net.Send(ply)
end

timer.Create("ValidatePills", 1, 0, function()
	for k, v in ipairs(player.GetAll()) do
		if !v.abilityCDs or IsValid(v.pk_pill_ent) then continue end

		net.Start("SlashModules.PillBind")
		net.WriteTable({})
		net.Send(v)
		
		v.abilityCDs = nil
	end
end)
hook.Add("OnEntityCreated", "PillInit", function(pill)
	if !string.StartsWith(pill:GetClass(), "pill_ent_") then return end

	timer.Simple(0, function()
		if !IsValid(pill) then return end

		local ply = pill:GetPillUser()
		if !IsValid(ply) then return end

		local pillForm = pill:GetPillForm()
		local pillTbl = pill.formTable

		ply.abilityCDs = {}

		for k, v in ipairs(pillTbl.abilities or {}) do
			ply.abilityCDs[k] = {}

			ply.abilityCDs[k].disabled = v.disabled
			ply.abilityCDs[k].time = 0
			ply.abilityCDs[k].cooldown = 0
		end

		net.Start("SlashModules.PillBind")
		net.WriteTable(ply.abilityCDs)
		net.Send(ply)
	end)
end)

function SlashModules.PillCameraPos(ply)
    local ent = pk_pills.getMappedEnt(ply)

    if !IsValid(ent) or ply:GetViewEntity() != ply then
        return ply:EyePos()
    end

    local formTable = ent.formTable
    local ang = ply:EyeAngles()
    local startpos

    if formTable.type == "phys" then
        local offset = (formTable.camera and formTable.camera.offset) or Vector(0, 0, 0)
        startpos = ent:LocalToWorld(offset)
    else
        startpos = ply:EyePos()
    end
    
    local dist
    local puppet = ent:GetPuppet()
    
    if formTable.camera and formTable.camera.bone and IsValid(puppet) then
        local boneID = puppet:LookupBone(formTable.camera.bone)
        if boneID then
            local bPos, bAng = puppet:GetBonePosition(boneID)
            if bPos then
                startpos = bPos + formTable.camera.offset
            end
        end
    end

    if formTable.type == "phys" and formTable.camera and formTable.camera.distFromSize then
        dist = ent:BoundingRadius()*5
    else
        dist = (formTable.camera and formTable.camera.dist) or 100
    end

    local underslung = formTable.camera and formTable.camera.underslung
    local right = formTable.camera and formTable.camera.right or 0
    local upDist = underslung and -dist/5 or dist/5
    
    local offsetVec = Vector(-dist, -right, upDist)
    offsetVec:Rotate(ang)
    
    local endpos = startpos + offsetVec
    if !formTable.noclip then
        local tr = util.TraceHull({
            start = startpos,
            endpos = endpos,
            filter = {ent, puppet, ply},
            mins = Vector(-5, -5, -5),
            maxs = Vector(5, 5, 5),
            mask = MASK_VISIBLE
        })

        return tr.HitPos
    end

    return endpos
end

function SlashModules.DisableAbility(ply, id, bool)
    local pill = ply.pk_pill_ent

    if !IsValid(pill) then return end

    local pillForm = pill:GetPillForm()
    local pillTbl = pill.formTable
	
	if isstring(id) then
		for k, v in ipairs(pillTbl.abilities or {}) do
			if v.name != id then continue end

			id = k
			break
		end
	end

    if !pillTbl.abilities or !pillTbl.abilities[id] then return end
	ply.abilityCDs = ply.abilityCDs or {}
	
	ply.abilityCDs[id] = ply.abilityCDs[id] or {}
	ply.abilityCDs[id].disabled = !bool

	net.Start("SlashModules.PillBind")
	net.WriteTable(ply.abilityCDs)
	net.Send(ply)
end

util.AddNetworkString('PILLSJUMPCAM')
function SlashModules.Jumpscare(ply)
    local ent = ply.pk_pill_ent

    if !IsValid(ent) then return end

	local entity = nil

	for k, v in pairs(ents.FindInSphere(ent:LocalToWorld(Vector(0, 0, 50)), 200)) do
		if v:IsPlayer() or v:IsNextBot() or v:IsNPC() then
			if v == ent or v == ply then continue end
			if (v:IsPlayer() and v:Team() != TEAM_SPECTATOR) or (v:IsNPC() or v:IsNextBot()) and v:Health() > 0 then
				entity = v
				break
			end
		end
	end

	if IsValid(entity) then
		local pill = ent:GetPuppet()

		if entity:IsPlayer() then
			entity:Freeze(true)
			entity:AddFlags(FL_NOTARGET)
			entity:DrawViewModel(false)
			entity:SetActiveWeapon(nil)

			net.Start('PILLSJUMPCAM')
			net.WriteEntity(pill)
			net.WriteBool(true)
			net.Send(entity)
		else
			entity:NextThink(CurTime() + 1e9) 
		end

		entity:SetPos(pill:GetPos() + pill:GetForward() * 100)

		ply:Freeze(true)

		-- Play the animation and sound for the entity performing the attack
		ent:PillAnim('jumpscare')
		ent:PillSound('jumpscare')

		entity:TakeDamage(1, ply)

		timer.Simple(.25, function()
			entity:TakeDamage(1, ply)

			ent:EmitSound("spiderbite2.wav")

			local offset = ply:GetRight() * math.Rand(0, 0) +
			pill:GetForward() * math.Rand(40, 40) +
			ply:GetUp() * math.Rand(80, 80)
			
			local effectdata = EffectData()
			effectdata:SetOrigin(ply:GetPos() + offset)
			effectdata:SetNormal(ent:GetAngles():Forward())
			effectdata:SetMagnitude(3)
			effectdata:SetScale(15)
			effectdata:SetColor(0)
			effectdata:SetFlags(3)
			util.Effect("bloodspray", effectdata)
			effectdata:SetOrigin(ply:GetPos() + offset)
			effectdata:SetNormal(ent:GetAngles():Forward())
			effectdata:SetMagnitude(3)
			effectdata:SetScale(15)
			effectdata:SetColor(0)
			effectdata:SetFlags(3)
			util.Effect("BloodImpact", effectdata)
			effectdata:SetOrigin(ply:GetPos() + offset)
			effectdata:SetNormal(ent:GetAngles():Forward())
			effectdata:SetMagnitude(3)
			effectdata:SetScale(15)
			effectdata:SetColor(0)
			effectdata:SetFlags(3)
			util.Effect("BloodSplash", effectdata)
		end)

		-- Timer to handle the next steps after the animation
		timer.Simple(.5, function()
			if !IsValid(entity) or !IsValid(ent) then return end

			-- Freeze and reset player settings
			ply:Freeze(false)

			-- Kill the player or damage the NPC
			if entity:IsPlayer() then
				entity:TakeDamage(999999, ply)
				net.Start('PILLSJUMPCAM')
				net.WriteEntity(pill)
				net.WriteBool(false)
				net.Send(entity)
				entity:RemoveFlags(FL_NOTARGET)
				entity:Freeze(false)
				entity:DrawViewModel(true)
			else
				entity:NextThink(CurTime()) 
				entity:TakeDamage(1e9, ply)
			end
		end)
	else
		-- No valid target, perform normal attack animation
	end

	timer.Simple(3, function()
		ply.OnHold = false
	end)
end

function SlashModules.SearchForTarget(ply, params)
    local pill = ply.pk_pill_ent
    if !IsValid(pill) then return end

	params = params or {}

	local bl = table.Copy(params.bl or {})
	table.Add(bl, {ply, pill, puppet})

	local puppet = pill.GetPuppet and pill:GetPuppet() or pill.GetPillAimEnt and pill:GetPillAimEnt()
	local searchPos = ply:EyePos() + ply:GetForward()*25
	
	local valid = {}
	for k, v in pairs(ents.FindInSphere(searchPos, 100)) do
		if !v:IsPlayer() and !v:IsNextBot() and !v:IsNPC() then continue end
		if v == ent or v == ply then continue end
		if (v:IsPlayer() and !v:IsValidTarget()) or ((v:IsNPC() or v:IsNextBot()) and v:Health() <= 0) then continue end
		if table.HasValue(bl, v) then continue end
		
		if !params.noclip then
			local tr = util.TraceLine({
				start = ply:WorldSpaceCenter(),
				endpos = v:WorldSpaceCenter(),
				filter = bl,
				mask = MASK_SHOT
			})
	
			if !tr.Hit or tr.Entity != v then continue end
		end

		table.insert(valid, {
			ent = v,
			dist = v:GetPos():Distance(searchPos)
		})
	end
	table.SortByMember(valid, "dist", true)

	return valid[1] and valid[1].ent
end

function SlashModules.BloodEffect(ply, nofade)
	local origin = ply:WorldSpaceCenter()
	local normal = VectorRand(-1, 1)
	
	local effectdata = EffectData()
	effectdata:SetOrigin(origin)
	effectdata:SetNormal(normal)
	effectdata:SetMagnitude(3)
	effectdata:SetScale(15)
	effectdata:SetColor(0)
	effectdata:SetFlags(3)
	util.Effect("bloodspray", effectdata)

	effectdata:SetOrigin(origin)
	effectdata:SetNormal(normal)
	effectdata:SetMagnitude(3)
	effectdata:SetScale(15)
	effectdata:SetColor(0)
	effectdata:SetFlags(3)
	util.Effect("BloodImpact", effectdata)

	effectdata:SetOrigin(origin)
	effectdata:SetNormal(normal)
	effectdata:SetMagnitude(3)
	effectdata:SetScale(15)
	effectdata:SetColor(0)
	effectdata:SetFlags(3)
	util.Effect("BloodSplash", effectdata)

	if nofade then return end
	
	ply:ScreenFade(SCREENFADE.IN, Color(50, 0, 0, 255), 1, .25)
end

function SlashModules.Attack(ply, attInfo)
    local pill = ply.pk_pill_ent
    if !IsValid(pill) or !attInfo or pill.attacking then return end

	local target = attInfo.target or SlashModules.SearchForTarget(ply)
	if !IsValid(target) then return end
	pill.attacking = true
	
	local puppet = pill.GetPuppet and pill:GetPuppet() or pill.GetPillAimEnt and pill:GetPillAimEnt()
	if attInfo.directAnim then
		local seq, dur = pill:LookupSequence(pill.formTable.anims.default[attInfo.anim or "attack"])
		
		pill:ResetSequence(seq)
		pill:SetCycle(0)
		
		timer.Simple(dur or 1, function()
			if !IsValid(pill) then return end
			
			pill:PillAnim(pill.formTable.anims.default["idle"], true)
		end)
	else
		pill:PillAnim(attInfo.anim or "attack", true)
	end

	pill:PillSound("attack")

	timer.Simple(attInfo.time, function()
		if !IsValid(pill) then return end
		
		timer.Simple(1, function()
			if !IsValid(pill) then return end
			pill.attacking = nil
		end)

		if !IsValid(target) or !target:Alive() then return end
		target:TakeDamage(attInfo.damage or 1, ply)
	end)

	for k, v in ipairs(attInfo.bloodImpacts or {}) do
		timer.Simple(v, function()
			SlashModules.BloodEffect(target)
		end)
	end
end

util.AddNetworkString("SlashModules.PillJumpscare")
function SlashModules.JumpscareV2(ply, jsInfo)
    local pill = ply.pk_pill_ent
    if !IsValid(pill) or !jsInfo then return end
	
	local target = jsInfo.target or SlashModules.SearchForTarget(ply)
	if !IsValid(target) then return end

	local receivers = {ply, target}
	local puppet = pill.GetPuppet and pill:GetPuppet() or pill.GetPillAimEnt and pill:GetPillAimEnt()
	local ragdoll

	if target:IsPlayer() then
		if jsInfo.ragdoll then
			target:SetNoDraw(true)

			ragdoll = ents.Create("prop_ragdoll")
			ragdoll:SetPos(target:GetPos() + Vector(0, 0, 15))
			ragdoll:SetModel(target:GetModel())
			ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)

			ragdoll:Spawn()
			ragdoll:Activate()

			for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
				local physId = ragdoll:TranslateBoneToPhysBone(i)
				if !physId or physId < 0 then continue end

				local physBone = ragdoll:GetPhysicsObjectNum(physId)

				local pos, ang = target:GetBonePosition(i)
				physBone:SetPos(pos)
				physBone:SetAngles(ang)
			end

			local startTime = CurTime()

			local offset = jsInfo.ragdoll.offset or Vector(0, 0, 0)
			local hookName = "jumpscare_"..tostring(ply)
            hook.Add("Think", hookName, function()
                if !IsValid(ragdoll) or !IsValid(puppet) then hook.Remove("Think", hookName) return end
				if startTime + (jsInfo.ragdoll.duration or 1) < CurTime() then hook.Remove("Think", hookName) return end

				local boneId = ragdoll:LookupBone(jsInfo.ragdoll.ragBone)
				if !boneId or boneId < 0 then return end
				
				local physId = ragdoll:TranslateBoneToPhysBone(boneId)
				if !physId or physId < 0 then return end
				
				local headPhys = ragdoll:GetPhysicsObjectNum(physId)
				if IsValid(headPhys) then
					local pos, ang = puppet:GetBonePosition(puppet:LookupBone(jsInfo.ragdoll.pillBone))

					headPhys:SetPos(pos + offset)
					headPhys:SetAngles(ang)
					headPhys:Wake()
				end
            end)

			SafeRemoveEntityDelayed(ragdoll, 30)
		end

		target:Freeze(true)
		target:AddFlags(FL_NOTARGET)
		target:DrawViewModel(false)
		target:SetActiveWeapon(nil)

		local jsInfo = table.Copy(jsInfo)
		jsInfo.onEnd = nil
		
		net.Start("SlashModules.PillJumpscare")
		net.WriteBool(true)
		net.WriteTable(jsInfo)
		net.WriteEntity(puppet)
		net.Send(receivers)
	else
		target:NextThink(CurTime() + 1e9) 
	end

	local modPos = jsInfo.pos or {}

	local tKey = tostring(target).."_kill"
	timer.Create(tKey, 0.1, 0, function()
		if !IsValid(ply) or !ply:Alive() then
			timer.Remove(tKey)
			return
		end

		target:SetPos(ply:GetPos() + ply:GetForward() * (modPos.forward or 50) + ply:GetUp() * (modPos.up or -25) + ply:GetRight() * (modPos.right or 0))

		local ang = (target:GetPos() - ply:GetPos()):Angle()
		ang.r = 0
		
		ply:SetEyeAngles(ang)
	end)

	ply:Freeze(true)

	pill:PillAnim("jumpscare")
	pill:PillSound("jumpscare")

	for k, v in ipairs(jsInfo.bloodImpacts or {}) do
		timer.Simple(v, function()
			SlashModules.BloodEffect(target, jsInfo.nofade)
			ply:ViewPunch(Angle(0, 0, math.random(2) == 1 and 1 or -1)*(jsInfo.punch or 10))
		end)
	end

	timer.Simple(jsInfo.time, function()
		if !IsValid(target) or !IsValid(pill) then return end
		timer.Remove(tKey)

		ply:Freeze(false)

		timer.Simple(0, function()
			if jsInfo.onEnd then
				jsInfo.onEnd(target)
			end
		end)

		if target:IsPlayer() then
			target:TakeDamage(999999, ply)

			timer.Simple(0, function()
				if jsInfo.ragdoll then
					local rag = target:GetRagdollEntity()
					SafeRemoveEntity(rag)
				end
			end)

			net.Start("SlashModules.PillJumpscare")
			net.WriteBool(false)
			net.Send(receivers)
			
			if jsInfo.ragdoll then
				target:SetNoDraw(false)
			end

			target:RemoveFlags(FL_NOTARGET)
			target:Freeze(false)
			target:DrawViewModel(true)
		else
			target:NextThink(CurTime()) 
			target:TakeDamage(1e9, ply)
		end
	end)
end

util.AddNetworkString("SlashModules.PillBind")
net.Receive("SlashModules.PillBind", function(len, ply)
    local pill = ply.pk_pill_ent

    if !IsValid(pill) then return end
	
	SlashModules.PillAbility(ply, net.ReadInt(4))
end)

local function isEmpty(vector, ignore)
    ignore = ignore or {}

    local point = util.PointContents(vector)
    local a = point != CONTENTS_SOLID
        and point != CONTENTS_MOVEABLE
        and point != CONTENTS_LADDER
        and point != CONTENTS_PLAYERCLIP
        and point != CONTENTS_MONSTERCLIP
    if !a then return false end

    local b = true

    for _, v in ipairs(ents.FindInSphere(vector, 35)) do
        if (v:IsNPC() or v:IsPlayer() or v:GetClass() == "prop_physics" or v.NotEmptyPos) and !table.HasValue(ignore, v) then
            b = false
            break
        end
    end

    return a and b
end

function SlashModules.findEmptyPos(pos, ignore, distance, step, area)
    if isEmpty(pos, ignore) and isEmpty(pos + area, ignore) then
        return pos
    end

    for j = step, distance, step do
        for i = -1, 1, 2 do
            local k = j * i

            if isEmpty(pos + Vector(k, 0, 0), ignore) and isEmpty(pos + Vector(k, 0, 0) + area, ignore) then
                return pos + Vector(k, 0, 0)
            end

            if isEmpty(pos + Vector(0, k, 0), ignore) and isEmpty(pos + Vector(0, k, 0) + area, ignore) then
                return pos + Vector(0, k, 0)
            end

            if isEmpty(pos + Vector(0, 0, k), ignore) and isEmpty(pos + Vector(0, 0, k) + area, ignore) then
                return pos + Vector(0, 0, k)
            end
        end
    end

    return pos
end