local meta = FindMetaTable("Player")

function SlashModules.ApplyTargetEffect(victim, attacker, effect)
    if not SherlockHNS then return victim:HangEffect(effect) end
    local name = "blast_" .. effect.name
    if not SherlockHNS.Effects[name] then
        SherlockHNS.RegisterEffect(name, {
            OnEnd = function(ply, fx)
                local active = ply:GetEffect(fx.data.name)
                if not active then return end
                if IsValid(active.trapEnt) then active.trapEnt:Remove() end
                if ply:HasEffect(fx.data.name) then ply:TakeEffect(fx.data.name, 999) end
            end,
        })
    end
    if not SherlockHNS.ApplyEffect(victim, name, effect.time, attacker, effect) then return false end
    -- Reapplication extends the native effect without calling OnStart again.
    -- Refresh the visual state and keep the current trap as its owner.
    return victim:HangEffect(effect)
end

util.AddNetworkString("SlashModules.Effects.Sync")
local function syncEffects(ply)
	net.Start("SlashModules.Effects.Sync")
	net.WriteEntity(ply)
	net.WriteTable(ply.Effects or {})
	net.Broadcast()
end

local function ResetEffect(ply, name)
	local fulltbl = SlashModules.Effects.List[name]

	if !fulltbl then return end

	local tname = ply:Name().." - "..name
	timer.Remove(tname)

	local effect = ply.Effects[name]

	if fulltbl.onvanish then
		fulltbl.onvanish(ply, ply.Effects[name], math.Round((effect.hangtime + effect.time - CurTime())))
	end

	ply.Effects[name] = nil
end

function meta:HangEffect(effecttbl)
	self.Effects = self.Effects or {}

	local se = "Milk"
	if self:HasEffect(se) and effecttbl.name != se and !effecttbl.bypet and !effecttbl.absolute then return end

	local effname = effecttbl.name
	local fulltbl = SlashModules.Effects.List[effname]

	if !fulltbl then return end

	local hangtbl = {}
	hangtbl.name = effname
	hangtbl.hangtime = CurTime()
	hangtbl.time = 1
	hangtbl.stats = fulltbl.stats

	for k, v in pairs(effecttbl) do
		hangtbl[k] = v
	end

	if fulltbl.debuff then
		hangtbl.time = hangtbl.time - hangtbl.time*((self.Stats or {}).debuffresist or 0)
	end

	hangtbl.stacks = math.Clamp(hangtbl.stacks or 1, 1, fulltbl.maxstacks or 1)
	
	if fulltbl.onhang then
		fulltbl.onhang(self, hangtbl)
	end

	self.Effects[effname] = hangtbl
	
	if fulltbl.tdelay and fulltbl.tfunc then
		fulltbl.tfunc(self, self.Effects[effname])

		local tname = self:Name().." - "..effname
		timer.Create(tname, fulltbl.tdelay or 1, 0, function()
			if !IsValid(self) then timer.Remove(tname) return end
			
			if fulltbl.tfunc then
				fulltbl.tfunc(self, self.Effects[effname])
			end
	
			if self.Effects[effname] and self.Effects[effname].hangtime + self.Effects[effname].time <= CurTime() then
				self:TakeEffect(effname, 999, 0)
			end
		end)
	else
		local tname = self:Name().." - "..effname
		timer.Create(tname, 1, 0, function()
			if !IsValid(self) then timer.Remove(tname) return end
	
			if self.Effects[effname] and self.Effects[effname].hangtime + self.Effects[effname].time <= CurTime() then
				self:TakeEffect(effname, 999, 0)
			end
		end)
	end
	
	syncEffects(self)
	SlashModules.UpdateStats(self)

	return true
end

function meta:StackEffect(effname, addstacks, updatehang)
	self.Effects = self.Effects or {}

	local se = "Milk"
	if self:HasEffect(se) and effname != se then return end

	local fulltbl = SlashModules.Effects.List[effname]
	local hasstacks = self:HasEffect(effname) or 0

	if !fulltbl or hasstacks <= 0 then return end

	local effecttbl = {}
	effecttbl.stacks = hasstacks+addstacks

	if updatehang then
		effecttbl.hangtime = CurTime()
	end

	self:UpdateEffect(effname, effecttbl)
	syncEffects(self)
	SlashModules.UpdateStats(self)

	return true
end

function meta:FreezeEffect(name, bool)
	self.Effects = self.Effects or {}

	local fulltbl = SlashModules.Effects.List[name]

	if !fulltbl then return end
	if !self.Effects[name] then return end
	local tname = self:Name().." - "..name
	
	local hangtbl = self.Effects[name]

	if bool then
		hangtbl.freezeleft = (self.Effects[name].hangtime + self.Effects[name].time) - CurTime()
	else
		if hangtbl.freezeleft then
			self.Effects[name].hangtime = CurTime()
			self.Effects[name].time = hangtbl.freezeleft
		end

		hangtbl.freezeleft = nil
	end

	self.Effects[name].hangtime = CurTime()

	if timer.Exists(tname) then
		if bool then
			timer.Pause(tname)
		else
			timer.UnPause(tname)
		end
	else
		timer.Create(tname, fulltbl.tdelay or 1, 0, function()
			if !IsValid(self) then timer.Remove(tname) return end

			if fulltbl.tfunc then
				fulltbl.tfunc(ply, self.Effects[name])
			end

			if self.Effects[name].hangtime + self.Effects[name].time <= CurTime() then
				self:TakeEffect(name, 999, true)
			end
		end)

		if bool then
			timer.Pause(tname)
		else
			timer.UnPause(tname)
		end
	end
	
	if self.Effects[name].stacks <= 0 then
		self.Effects[name] = nil
	end
	
	syncEffects(self)
	SlashModules.UpdateStats(self)

	return true
end

function meta:UpdateEffect(name, update, canwait)
	self.Effects = self.Effects or {}

	local fulltbl = SlashModules.Effects.List[name]

	if !fulltbl then return end
	if !self.Effects[name] then return end

	for k, v in pairs(update) do
		self.Effects[name][k] = v
	end

	self.Effects[name].stacks = math.Clamp(self.Effects[name].stacks, 0, fulltbl.maxstacks or 1)

	if self.Effects[name].stacks <= 0 and !fulltbl.canZero then
		ResetEffect(self, name, 999)
	end
	
	syncEffects(self)
	SlashModules.UpdateStats(self)

	return true
end

function meta:TakeEffect(name, stacks, timeleft, nosync)
	self.Effects = self.Effects or {}

	local fulltbl = SlashModules.Effects.List[name]

	if !fulltbl then return end
	if !self.Effects[name] then return end

	self.Effects[name].stacks = self.Effects[name].stacks-stacks
	self.Effects[name].stacks = math.Clamp(self.Effects[name].stacks, 0, fulltbl.maxstacks or 1)

	if self.Effects[name].stacks <= 0 then
		ResetEffect(self, name)
	end
	
	syncEffects(self)
	SlashModules.UpdateStats(self)

	return true
end

function meta:ResetEffects()
	self.Effects = self.Effects or {}

	for k, v in pairs(self.Effects or {}) do
		if v.quest then continue end

		self:TakeEffect(k, 999, 999)
	end

	--self.Effects = {}
	
	syncEffects(self)
	SlashModules.UpdateStats(self)

	return true
end

hook.Add("PlayerSpawn", "ResetEffects", function(ply)
	ply:ResetEffects()
	SlashModules.UpdateStats(ply)
end)

hook.Add("PlayerInitialSpawn", "ResetEffects", function(ply)
	ply:ResetEffects()
	SlashModules.UpdateStats(ply)

	for _, ent in ipairs(ents.FindByClass("env_fog_controller")) do
		ent:Remove()
	end
end)

hook.Add("PostPlayerDeath", "ResetEffects", function(ply)
	ply:ResetEffects()
end)