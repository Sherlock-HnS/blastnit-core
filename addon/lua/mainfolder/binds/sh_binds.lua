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

-- Keep the original physical binds for actions without a Source IN_* code.
function SlashModules.ConfigureHNSAbilities(form)
    local sourceKeys = { [KEY_R] = IN_RELOAD, [KEY_E] = IN_USE, [KEY_LSHIFT] = IN_SPEED }
    form.hnsBlastNames = {}
    form.hnsBlastButtons = {}
    for i, action in ipairs(form.abilities) do
        local id = "blast_" .. string.lower(action.name):gsub("%W+", "_")
        form.hnsBlastNames[action.name] = id
        local key = sourceKeys[action.key]
        local label = action.keyText
        local def = {
            id = id, name = action.name, order = i, key = key,
            keyLabel = action.hnsKeyLabel or label, icon = action.hnsIcon, cooldown = action.cooldown,
            OnUse = function(ply, ent)
                local result = action.func(ply, ent)
                if isnumber(result) then SherlockHNS.Ability.SetCooldown(ply, id, result) end
                return result
            end,
        }
        if action.name == "Night Vision" then
            def.toggle = true
            def.OnUse = function(ply, ent) ent:SetNWBool("blast_night_vision", true) end
            def.OnEnd = function(ply, ent)
                if IsValid(ent) then ent:SetNWBool("blast_night_vision", false) end
            end
        end
        if not key and isnumber(action.key) then form.hnsBlastButtons[action.key] = id end
        table.insert(form.hnsAbilities, def)
    end
    form.abilities = nil
end

if SERVER then
    hook.Add("PlayerButtonDown", "BlastHNSAbilities", function(ply, button)
        local ent = ply.pk_pill_ent
        local buttons = IsValid(ent) and ent.formTable and ent.formTable.hnsBlastButtons
        if buttons and buttons[button] then SherlockHNS.Ability.Use(ply, buttons[button]) end
    end)
end


hook.Add("SetupMove", "BlastHNSWeb", function(ply, mv)
    if not SherlockHNS or not IsValid(ply:GetNWEntity("blast_web_trap")) then return end
    mv:SetForwardSpeed(0)
    mv:SetSideSpeed(0)
    mv:SetUpSpeed(0)
    -- Sem tirar o IN_JUMP, cada aperto de espaço dava um pulinho e, com a
    -- velocidade zerada no tick seguinte, a vítima ficava flutuando. O KeyPress
    -- do servidor (usado para escapar) não é afetado.
    mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
    mv:SetVelocity(vector_origin)
end)
