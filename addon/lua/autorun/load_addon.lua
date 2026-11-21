SlashModules = SlashModules or {}

function SlashModules:LoadClient(file)
    if SERVER then
        AddCSLuaFile(file)
    else
        include(file)
    end
end

function SlashModules:LoadServer(file)
    if SERVER then
        include(file)
    end
end

function SlashModules:LoadShared(file)
    self:LoadServer(file)
    self:LoadClient(file)
end

function SlashModules:LoadFolder(folder, name)
    local files, dirs = file.Find(folder .. "/*", "LUA")

    for _, file in ipairs(files) do
        local realm = string.sub(file, 1, 3)
        local filePath = folder .. "/" .. file

        if realm == "cl_" then
            self:LoadClient(filePath)
            MsgC(color_white, "[", Color(150, 100, 255), "Slash Modules", color_white, "]", Color(255, 222, 131), " Loaded Client File: "..filePath, "\n")
        elseif realm == "sh_" then
            self:LoadShared(filePath)
            MsgC(color_white, "[", Color(150, 100, 255), "Slash Modules", color_white, "]", Color(131, 255, 193), " Loaded Shared File: "..filePath, "\n")
        elseif realm == "sv_" then
            self:LoadServer(filePath)
            MsgC(color_white, "[", Color(150, 100, 255), "Slash Modules", color_white, "]", Color(131, 220, 255), " Loaded Server File: "..filePath, "\n")
        else
            MsgC(color_white, "[", Color(150, 100, 255), "Slash Modules", color_white, "]", Color(255, 100, 100), " Invalid File Format: "..file, "\n")
        end
    end

    for _, dir in ipairs(dirs) do
        MsgC(color_white, "[", Color(150, 100, 255), "Slash Modules", color_white, "]", Color(200, 200, 200), " Loading Folder: "..folder.."/"..dir, "\n")
        self:LoadFolder(folder .. "/" .. dir)
    end

    MsgC(color_white, "[", Color(150, 100, 255), "Slash Modules", color_white, "]", " "..(name or "Untitled").." Addon Finished Loading", "\n")
end

hook.Add("SlashUI.PostLoad", "LoadCore", function()
    SlashModules:LoadFolder("libraries", "CoreLibrary")
    SlashModules:LoadFolder("mainfolder", "Core")

    if !CLIENT then return end

    -- for k=1, 250 do
    --     SlashUI:CreateFont("AmericSlash"..k, k, nil, {
    --         font = "American Captain Cyrillic"
    --     })
    
    --     SlashUI:CreateFont("AestheticSlash"..k, k, nil, {
    --         font = "Aesthetic DEMO"
    --     })
    -- end
end)