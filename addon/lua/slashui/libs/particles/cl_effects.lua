SlashUI.EmitterPresets = {
    ["FishExplode"] = function(ent, args)
        local effcol = Color(90, 0, 0)
        
        local size = 3

        local pos = args.pos

        EmitSound("fish_death.ogg", pos)
    
        local emitter = ParticleEmitter(pos)
        for k=1, 100 do
            local dir = Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-1, 1))*300
    
            local particle = emitter:Add(Material("icon16/bullet_white.png"), pos)
    
            particle:SetColor(effcol.r, effcol.g, effcol.b)
            particle:SetDieTime(5)
            particle:SetStartAlpha(255)
            particle:SetStartSize(size)
            particle:SetEndSize(size)
            particle:SetCollide(true)
            particle:SetBounce(0)
            particle:SetAirResistance(1)
            particle:SetNextThink(CurTime())
            particle:SetVelocity(dir)
            particle:SetGravity(Vector(0, 0, -750))
        end

        emitter:Finish()
    end,
    ["FishBounce"] = function(ent, args)
        local icon = args.icon

        local lifeTime = 5
        local color = color_white
        
        if !icon or isstring(icon) then return end

        local pos = args.pos
        local size = math.max(args.size or 0, 5)
        local dir = args.dir

        local emitter = ParticleEmitter(pos)
        local particle = emitter:Add(icon, pos)

        particle:SetDieTime(lifeTime)

        particle:SetStartAlpha(255)
        particle:SetEndAlpha(255)

        particle:SetStartSize(size)
        particle:SetEndSize(size)

        particle:SetGravity(Vector(0, 0, -1000))
        particle:SetCollide(true)

        particle:SetBounce(1)
        --particle:SetNextThink(CurTime())

        particle:SetVelocity(dir*100)
        particle:SetColor(color.r, color.g, color.b)

        particle:SetCollideCallback(function(part, hitpos, hitnormal)
            EmitSound("fish_damage.ogg", hitpos)
        end)

        emitter:Finish()

        timer.Simple(lifeTime, function()
            local tr = util.TraceLine({
                start = particle:GetPos(),
                endpos = particle:GetPos(),
                mask = MASK_WATER
            })

            if !(tr.Hit and tr.HitWorld) then
                local newArgs = {
                    pos = particle:GetPos()
                }
    
                SlashUI.Emit("FishExplode", 1, ent, newArgs)
            end
        end)
    end,
    ["EmojiAura"] = function(ent, args)
        local icon = SlashUI:GetIcon(args.icon)

        local lifeTime = 3
        
        if !icon or isstring(icon) then return end

        local pos = ent:GetPos() + Vector(math.random(-20, 20), math.random(-20, 20), 0)
        local size = 2

        local emitter = ParticleEmitter(pos)
        local particle = emitter:Add(icon, pos)

        particle:SetDieTime(lifeTime)

        particle:SetStartAlpha(255)
        particle:SetEndAlpha(0)

        particle:SetStartSize(size)
        particle:SetEndSize(size)

        particle:SetGravity(Vector(0, 0, 25))
        particle:SetCollide(false)

        emitter:Finish()
    end,
}

function SlashUI.Emit(name, amount, parent, args)
    local eTbl = SlashUI.EmitterPresets[name]
    if !eTbl or !IsValid(parent) then return end

    for k=1, amount or 1 do
        eTbl(parent, args or {})
    end
end

net.Receive("SlashUI.Emitter", function(len)
    local EmitName = net.ReadString()
    local EmitAmount = net.ReadInt(32)
    local EmitParent = net.ReadEntity()
    local EmitArgs = net.ReadTable() or {}

    if EmitArgs.icon and isstring(EmitArgs.icon) then
        EmitArgs.icon = Material(EmitArgs.icon..".png")
    end

    PrintTable(EmitArgs)

    SlashUI.Emit(EmitName, EmitAmount, EmitParent, EmitArgs)
end)