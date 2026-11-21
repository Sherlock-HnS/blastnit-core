function SlashUI:Ease(t, b, c, d)
	t = t / d
	local ts = t * t
	local tc = ts * t


	return b + c * (-2 * tc + 3 * ts)
end

function SlashUI:EaseInOutQuintic(t, b, c, d)
	t = t / d
	local ts = t * t
	local tc = ts * t


	return b + c * (6 * tc * ts + -15 * ts * ts + 10 * tc)
end

function SlashUI:RemoveDebounce(name)
	timer.Remove("_debounce." .. name)
end

function SlashUI:Debounce(name, wait, func)
	if timer.Exists("_debounce." .. name) then
		timer.Remove("_debounce." .. name)
	end

	timer.Create("_debounce." .. name, wait, 1, function()
		func()

		timer.Remove("_debounce." .. name)
	end)
end

if SERVER then
	util.AddNetworkString("SlashUI.FullClientInit")

	net.Receive("SlashUI.FullClientInit", function(len, p)
		if p.SlashUI_FullClientInit then
			return
		end

		hook.Run("slash.OnClientFullInit", p)

		p.SlashUI_FullClientInit = true
	end)
else
	hook.Add("SetupMove", "slash.FullClientInit", function()
		timer.Simple(15, function()
			net.Start("SlashUI.FullClientInit")
			net.SendToServer()
		end)

		hook.Remove("SetupMove", "slash.FullClientInit")
	end)
end

function SlashUI:LerpColor(fract, from, to)
	return Color(Lerp(fract, from.r, to.r), Lerp(fract, from.g, to.g), Lerp(fract, from.b, to.b), Lerp(fract, from.a or 255, to.a or 255))
end

function SlashUI:GetAngleBetweenTwoVectors(a, b)
	local vec = (a - b):GetNormalized()
	local ang = vec:Angle()

	return ang
end

function SlashUI:GetVector2DDistance(a, b)

	return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2)
end


function SlashUI:LerpVector(frac, from, to, ease)
	local newFract = ease and ease(frac, 0, 1, 1) or SlashUI:Ease(frac, 0, 1, 1)

	return LerpVector(newFract, from, to)
end

function SlashUI:LerpAngle(frac, from, to, ease)
	local newFract = ease and ease(frac, 0, 1, 1) or SlashUI:Ease(frac, 0, 1, 1)

	return LerpAngle(newFract, from, to)
end

if SERVER then
	util.AddNetworkString("SlashUI.OSTime")

	hook.Add("PlayerInitialSpawn", "SlashUI.OSTime", function(p)
		net.Start("SlashUI.OSTime")
		net.WriteFloat(os.time())
		net.WriteFloat(CurTime())
		net.Send(p)
	end)
else
	os._SVRDiff = 0

	net.Receive("SlashUI.OSTime", function()
		local ostime = net.ReadFloat()
		local ct = net.ReadFloat()

		os._SVRDiff = os.time() - ostime + ct - CurTime()
	end)

	function os.ServerTime()
		return os.time() - os._SVRDiff
	end

	local function TCMD()
		print(os.time(), os.ServerTime(), os.date("%I:%M %p", os.time()), os.date("%I:%M %p", os.ServerTime()))
	end
	concommand.Add("print_servertime", TCMD)
end

function SlashUI:Map(tbl, func)
	local newTbl = {}
	for i, v in pairs(tbl) do
		newTbl[i] = func(v, i)
	end

	return newTbl
end


function SlashUI:Hue2RGB(p, q, t)
	if t < 0 then t = t + 1 end
	if t > 1 then t = t - 1 end
	if t < 1 / 6 then return p + (q - p) * 6 * t end
	if t < 1 / 2 then return q end
	if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
	return p
end


function SlashUI:HSLToColor(h, s, l, a)
	local r, g, b
	local t = h / (2 * math.pi)

	if s == 0 then
		r, g, b = l, l, l
	else
		local q
		if l < 0.5 then
			q = l * (1 + s)
		else
			q = l + s - l * s
		end
		local p = 2 * l - q

		r = self:Hue2RGB(p, q, t + 1 / 3)
		g = self:Hue2RGB(p, q, t)
		b = self:Hue2RGB(p, q, t - 1 / 3)
	end

	return Color(r * 255, g * 255, b * 255, (a or 1) * 255)
end


function SlashUI:ColorToHSL(col)
	local r = col.r / 255
	local g = col.g / 255
	local b = col.b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local b = max + min
	local h = b / 2
	if max == min then return 0, 0, h end
	local s, l = h, h
	local d = max - min
	s = l > .5 and d / (2 - b) or d / b
	if max == r then h = (g - b) / d + (g < b and 6 or 0)
	elseif max == g then
		h = (b - r) / d + 2
	elseif max == b then
		h = (r - g) / d + 4
	end
	return h * .16667, s, l
end

function SlashUI:DecToHex(d, zeros)
	return string.format("%0" .. (zeros or 2) .. "x", d)
end

function SlashUI:RGBToHex(color)
	return "#" .. self:DecToHex(math.max(math.min(color.r, 255), 0)) .. self:DecToHex(math.max(math.min(color.g, 255), 0)) .. self:DecToHex(math.max(math.min(color.b, 255), 0))
end

function SlashUI:HexToRGB(hex)
	hex = hex:gsub("#", "")

	if (#hex == 3) then
		local r = hex:sub(1, 1)
		local g = hex:sub(2, 2)
		local b = hex:sub(3, 3)

		return Color(tonumber("0x" .. r .. r), tonumber("0x" .. g .. g), tonumber("0x" .. b .. b))
	end

	return Color(tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6)))
end

function SlashUI:InsertIntoEmpty(tbl, value)
	for i=1, #tbl do
        if tbl[i] and tbl[i] != nil then continue end

		tbl[i] = value
		return i
	end
	
	local i = #tbl + 1
    tbl[i] = value

    return i
end

function SlashUI:GetFirstKey(tbl)
    local lastKey = math.huge

    for k, v in pairs(tbl) do
		if !tonumber(k) then continue end

        lastKey = math.min(tonumber(k), lastKey)
    end

    return lastKey
end

function SlashUI:GetLastKey(tbl)
    local lastKey = 0

    for k, v in pairs(tbl) do
		if !tonumber(k) then continue end

        lastKey = math.max(tonumber(k), lastKey)
    end

    return lastKey
end