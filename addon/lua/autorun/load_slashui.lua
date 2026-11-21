SlashUI = SlashUI or {}

function SlashUI:CreateFont(name, size, weight, mergeTbl)
	local tbl = {
		font = "Montserrat Medium",

		size = size + 2,
		weight = weight or 500,
		extended = true
	}

	if mergeTbl then
		table.Merge(tbl, mergeTbl)
	end

	surface.CreateFont(name, tbl)
end

if CLIENT then
    for k=1, 500 do
        SlashUI:CreateFont("Slash"..k, k)
    end
end

function SlashUI:LoadClient(file)
    if SERVER then
        AddCSLuaFile(file)
    else
        include(file)
    end
end

function SlashUI:LoadServer(file)
    if SERVER then
        include(file)
    end
end

function SlashUI:LoadShared(file)
    self:LoadServer(file)
    self:LoadClient(file)
end

function SlashUI:LoadFolder(folder, name)
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

hook.Run("SlashUI.PreLoad")
SlashUI:LoadFolder("slashui", "Framework")
hook.Run("SlashUI.PostLoad")