hook.Add("PlayerFootstep", "pk_pill_step", function(ply, pos, foot, snd, vol, filter)
    local ent = ply.pk_pill_ent

    if !IsValid(ent) then return end
    if SERVER then return true end

    if ent.formTable.type == "phys" or ent.formTable.muteSteps or ent.animFreeze then
        return true
    elseif ent.formTable.sounds and ent.formTable.sounds.step then
        if istable(ent.formTable.sounds.step) then
            ent.stepNum = (ent.stepNum or 0) + 1
            if ent.stepNum > #ent.formTable.sounds.step then
                ent.stepNum = 1
            end

            ent:EmitSound(ent.formTable.sounds.step[ent.stepNum])
        else
            ent:PillSound("step", pos)
        end
        
        return true
    end
end)

hook.Add("SetupMove", "DisableJump", function(ply, mv, cmd)
    local pill = ply.pk_pill_ent
    
    if IsValid(pill) and pill.formTable.canJump == false then
        if mv:KeyDown(IN_JUMP) then
            mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
        end
    end
end)