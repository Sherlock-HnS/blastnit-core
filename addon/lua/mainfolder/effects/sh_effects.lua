SlashModules.Effects = SlashModules.Effects or {}
SlashModules.Effects.List = SlashModules.Effects.List or {}

function SlashModules.Effects.Register(key, tbl)
    SlashModules.Effects.List[key] = tbl
end

SlashModules.Effects.Register("Highlighted", {
    color = color_white,
    stats = {},
    maxstacks = 1,
})

SlashModules.Effects.Register("Web Trapped", {
    color = SlashUI.Theme.Green,
    stats = {
        ms = -999,
        jp = -999,
    },
    maxstacks = 1,
})

SlashModules.Effects.Register("Spider Boost", {
    color = color_white,
    stats = {
        ms = 300,
    },
    maxstacks = 1,
})

SlashModules.Effects.Register("Spider Camo", {
    color = color_white,
    stats = {},
    maxstacks = 1,
})

SlashModules.Effects.Register("Plushtrapped", {
    color = color_white,
    stats = {
        ws = -100,
    },
    maxstacks = 5,
    tdelay = 0,
    tfunc = function(ply, effTbl)
        local plush = effTbl.plushtrap

        if IsValid(plush) then
            if plush:GetMoveType() == MOVETYPE_NOCLIP then
                plush:SetPos(ply:EyePos() - Vector(0, 0, 40) - ply:GetAngles():Forward()*15)
                --plush:SetEyeAngles(ply:EyeAngles())

                if IsValid(ply.fakePlush) then
                    local ang = ply:EyeAngles()
                    ang.p = 0

                    ply.fakePlush:SetPos(ply:EyePos() - Vector(0, 0, 40) - ply:GetAngles():Forward()*15)
                end
            else
                ply:TakeEffect("Plushtrapped", 999)
            end
        end

        if effTbl.lastHit <= CurTime() then
            effTbl.lastHit = CurTime() + 1
            ply:TakeDamage(5) 

            if IsValid(ply.fakePlush) then
                ply.fakePlush:Scratch()
            end

            ply:EmitSound("physics/flesh/flesh_bloody_break.wav", nil, math.Rand(75, 150))
            
            local effectdata = EffectData()
            
            effectdata:SetOrigin(ply:LocalToWorld(ply:OBBCenter()) + VectorRand(-15, 15))
            effectdata:SetNormal(ply:GetAngles():Forward())
            effectdata:SetMagnitude(3)
            effectdata:SetScale(15)
            effectdata:SetColor(0)
            effectdata:SetFlags(3)
            util.Effect("BloodImpact", effectdata)
        end
    end
})

SlashModules.Effects.Register("Obelisk Run", {
    color = color_white,
    stats = {
        ms = 400,
    },
    maxstacks = 1,
})

SlashModules.Effects.Register("Obelisk Blind", {
    color = color_white,
    stats = {},
    maxstacks = 1,
})

local meta = FindMetaTable("Player")

function meta:IsValidTarget()
    if self:Team() == TEAM_SPECTATOR or !self:Alive() then return false end
    if IsValid(self.pk_pill_ent) then return false end

	return true
end

function meta:HasEffect(eff)
    local currenteffects = self.Effects or {}
    local has = currenteffects[eff] and currenteffects[eff].stacks or false

	return has
end

function meta:GetEffect(eff)
    local currenteffects = self.Effects or {}
    local has = currenteffects[eff] or false

	return has
end

hook.Run("SlashModules.Effects.Loaded")