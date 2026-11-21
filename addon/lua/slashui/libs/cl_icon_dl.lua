SlashUI.CachedIcons = SlashUI.CachedIcons or {}

if (!file.IsDir("slash/icons", "DATA")) then
	file.CreateDir("slash/icons")
end
if (!file.IsDir("slash/icons/imgur", "DATA")) then
	file.CreateDir("slash/icons/imgur")
end

local function DownloadImage(tbl)
	local p = SlashUI.Promises.new()

	if (!isstring(tbl.id)) then
		return p:reject("ID invalid")
	end

	local id = tbl.id
	local idLower = id:lower()
	local url = tbl.url or "https://i.imgur.com"
	local type = tbl.type or "png"

	if (SlashUI.CachedIcons[id] and SlashUI.CachedIcons[id] != "Loading") then
		return p:resolve(SlashUI.CachedIcons[id])
	end

	local read = file.Read("slash/icons/imgur/" .. idLower .. "." .. type)
	if read then
		SlashUI.CachedIcons[id] = Material("../data/slash/icons/imgur/" .. idLower .. "." .. type, "smooth")
		SlashUI.CachedIcons[id.."_nc"] = Material("../data/slash/icons/imgur/" .. idLower .. "." .. type, "noclamp")
	
		return p:resolve(SlashUI.CachedIcons[id])
	end

	local fullURL = tbl.fullURL or url .. "/" .. id .. "." .. type
	http.Fetch(fullURL, function(body, size, headers, code)
		if (code != 200) then
			return p:reject("Unable to download image due to code not being 200. Code: " .. code .. " ID:  " .. id .. " URL: " .. url .. "/" .. id .. "." .. type)
		end

		local str = "slash/icons/imgur/" .. idLower .. "." .. type
		file.Write(str, body)

		SlashUI.CachedIcons[id] = Material("../data/" .. str, "smooth")
		SlashUI.CachedIcons[id.."_nc"] = Material("../data/" .. str, "noclamp")

		p:resolve(SlashUI.CachedIcons[id])
	end, function(err)
		p:reject("Unable to download image. ID: " .. id .. " URL: " .. url .. "/" .. id .. "." .. type)
	end)

	return p
end

function SlashUI:DownloadIcon(pnl, tbl, pnlVar)
	if (!tbl) then return end

	local p = SlashUI.Promises.new()

	if isstring(tbl) then
		tbl = {
		{
		id = tbl } }
	end

	local i = 1
	local function AsyncDownload()
		if (!tbl[i]) then p:reject()end

		pnl[pnlVar or "Icon"] = "Loading"
		DownloadImage(tbl[i]):next(function(result)
			p:resolve(result):next(function()
				pnl[pnlVar or "Icon"] = result
				pnl[(pnlVar or "Icon").."_nc"] = SlashUI.CachedIcons[tbl[i].id.."_nc"]
			end, function(err)
				print(err)
			end)
		end, function(err)
			print(err)

			i = i + 1

			AsyncDownload()
		end)
	end

	AsyncDownload()

	return p
end

function SlashUI:DrawIcon(x, y, w, h, pnl, col, loadCol, var, nc)
	col = col or color_white
	loadCol = loadCol or SlashUI.Theme.Accent
	var = var or "Icon"

	if nc then
		var = var.."_nc"
	end

	if (pnl[var] and type(pnl[var]) == "IMaterial") then
		surface.SetMaterial(pnl[var])
		surface.SetDrawColor(col)
		surface.DrawTexturedRect(x, y, w, h)
	elseif (pnl[var] != nil) then
		SlashUI:DrawLoadingCircle(h, h, h, loadCol)
	end
end

function SlashUI:DrawIconRotated(x, y, w, h, rot, pnl, col, loadCol, var, nc)
	col = col or color_white
	loadCol = loadCol or SlashUI.Theme.Accent
	var = var or "Icon"

	if nc then
		var = var.."_nc"
	end

	if (pnl[var] and type(pnl[var]) == "IMaterial") then
		surface.SetMaterial(pnl[var])
		surface.SetDrawColor(col)
		surface.DrawTexturedRectRotated(x, y, w, h, rot)
	elseif (pnl[var] != nil) then
		SlashUI:DrawLoadingCircle(h, h, h, loadCol)
	end
end

function SlashUI:GetIcon(id)
	local _type = type(id)
	if (_type == "IMaterial") then
		return id
	end

	if self.CachedIcons[id] then
		return self.CachedIcons[id]
	end

	local read = file.Read("slash/icons/" .. id:lower() .. ".png")
	if read then
		self.CachedIcons[id] = Material("../data/slash/icons/" .. id:lower() .. ".png", "smooth")
		self.CachedIcons[id.."_nc"] = Material("../data/slash/icons/" .. id:lower() .. ".png", "noclamp")
	else
		self.CachedIcons[id] = "Loading"
	end

	http.Fetch("https://i.imgur.com/" .. id .. ".png", function(body, len)
		local str = "slash/icons/" .. id:lower() .. ".png"
		file.Write(str, body)

		self.CachedIcons[id] = Material("../data/" .. str, "smooth")
		self.CachedIcons[id.."_nc"] = Material("../data/" .. str, "noclamp")
	end)
end
