local defaultStats = {
	ms = 200,
	jp = 200,
}

function SlashModules.UpdateStats(ply, instantly)
    local pill = ply.pk_pill_ent

    if IsValid(pill) then
        local pillForm = pill:GetPillForm()
        local pillTbl = pill.formTable

        ply.Stats = {
            ms = pillTbl.moveSpeed.walk,
            jp = pillTbl.jumpPower or defaultStats.jp,
            rs = pillTbl.moveSpeed.run,
        }
    else
        ply.Stats = table.Copy(defaultStats)
    end

    local stunned = false
    for k, v in pairs(ply.Effects or {}) do
        local fulltbl = SlashModules.Effects.List[k]
        local stacks = v.stacks or 1

        if fulltbl.stun then
            stunned = true
        end

        for k1, v1 in pairs(v.stats or {}) do
            if !ply.Stats[k1] then continue end
            ply.Stats[k1] = ply.Stats[k1] + v1
        end

        for k1, v1 in pairs(fulltbl.statsperstack or {}) do
            if !ply.Stats[k1] then continue end
            ply.Stats[k1] = ply.Stats[k1] + v1*stacks
        end
    end
    
    ply.Stats.ms = math.max(ply.Stats.ms, 1)

    ply:SetWalkSpeed(ply.Stats.ms)
    ply:SetRunSpeed(ply.Stats.rs or ply.Stats.ms*2)
    ply:SetCrouchedWalkSpeed(.5)
    ply:SetSlowWalkSpeed(ply.Stats.ms*.5)
    ply:SetJumpPower(ply.Stats.jp)

    return ply.Stats
end

function SlashModules.NoEffectsStats(ply)
    local Stats = table.Copy(SlashModules.Character.DefaultStats)

    return Stats
end