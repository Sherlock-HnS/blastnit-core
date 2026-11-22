local defaultStats = {
	ms = 200,
	jp = 200,
}

function SlashModules.UpdateStats(ply, instantly)
    local pill = ply.pk_pill_ent

    if IsValid(pill) and pill.formTable then
        local pillTbl = pill.formTable

        ply.Stats = {
            ms = (pillTbl.moveSpeed or {}).walk or 200,
            jp = pillTbl.jumpPower or defaultStats.jp,
            rs = (pillTbl.moveSpeed or {}).run or 500,
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

    if SherlockHNS then
        -- Runner movement belongs to the gamemode. The web restricts input
        -- while it is attached, so releasing it restores the current speed.
        if IsValid(pill) then
            if ply:HasEffect("Spider Boost") then
                pk_pills.setCostumeMoveSpeed(pill, ply.Stats.ms, ply.Stats.rs, nil, ply.Stats.jp)
                pill.blastBoostApplied = true
            elseif pill.blastBoostApplied then
                pill.blastBoostApplied = nil
                pk_pills.setCostumeMoveSpeed(pill)
            end
        end
        return ply.Stats
    end
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