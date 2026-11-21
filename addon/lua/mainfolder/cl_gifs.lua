local gifs = {
    ["retro_freddy_jumpscare"] = {speed = .065}, -- 1522x856
    ["retro_chica_jumpscare"] = {speed = .065}, -- 1522x856
}

for dir, v in pairs(gifs) do
    local path = "materials/gifs/"..dir.."/"
    local files = file.Find(path.."*", "GAME") or {}

    for k, v in pairs(files) do
        files[k] = tonumber(string.StripExtension(v))
    end

    table.sort(files, function(a, b) return a < b end)

    local new = {}
    for k, v in pairs(files) do
        new[k] = Material(path..v..".png", "smooth mips")
    end

    gifs[dir].frames = new

    gifs[dir].maxFrames = #new
    gifs[dir].currentFrame = 0

    gifs[dir].frameChange = CurTime()
end

SlashModules = SlashModules or {}

function SlashModules.PingPong(speed)
    local t = CurTime() * speed
    return 1 - math.abs((t % 1) * 2 - 1)
end

function SlashModules.GIFLength(gif)
    local gifTbl = gifs[gif]

    if !gifTbl then return 0 end

    if gifTbl.specialFrames then
        local length = 0

        for i=1, gifTbl.maxFrames do
            if gifTbl.specialFrames[i] then
                length = length*gifTbl.specialFrames[i]
            else
                length = length*gifTbl.speed
            end
        end

        return length
    else
        return gifTbl.maxFrames*gifTbl.speed
    end
end

function SlashModules.GIFReset(gif)
    local gifTbl = gifs[gif]

    if !gifTbl then return end

    gifTbl.currentFrame = 0
    gifTbl.frameChange = CurTime()
end

function SlashModules.RandomGIF()
    local rVal, rKey = table.Random(gifs)

    return rKey, SlashModules.GIFLength(rKey)
end

function SlashModules.DrawGIF(gif, x, y, w, h, color, r)
    local gifTbl = gifs[gif]

    if !gifTbl then return end

    if gifTbl.frameChange < CurTime() then
        gifTbl.currentFrame = gifTbl.currentFrame + 1

        if gifTbl.currentFrame > gifTbl.maxFrames then
            gifTbl.currentFrame = 1
        end

        if gifTbl.specialFrames and gifTbl.specialFrames[gifTbl.currentFrame] then
            gifTbl.frameChange = CurTime() + gifTbl.specialFrames[gifTbl.currentFrame]
        else
            gifTbl.frameChange = CurTime() + gifTbl.speed
        end
    end

    if !gifTbl.frames[gifTbl.currentFrame] then return end

    RNDX.DrawMaterial(r or 0, x, y, w, h, color or color_white, gifTbl.frames[gifTbl.currentFrame])
end

concommand.Add("slash_gifs", function(ply)
	if IsValid(TestingFrame) then TestingFrame:Remove() end

	TestingFrame = vgui.Create("SlashUI.Frame")
	TestingFrame:SetSize(ScrW(), ScrH())
	TestingFrame:Center()
	TestingFrame:MakePopup()
	TestingFrame:SetAlpha(0)
	TestingFrame:AlphaTo(255, .25)
	TestingFrame:SetTitle("GIF TEST")

    TestingFrame.SP = TestingFrame:Add("SlashUI.Scrollpanel.Wyvern")
    TestingFrame.SP:Dock(FILL)
    TestingFrame.SP:DockMargin(8, 8, 8, 8)

    TestingFrame.iLayout = TestingFrame.SP:Add("DIconLayout")
    TestingFrame.iLayout:Dock(FILL)
    TestingFrame.iLayout:DockMargin(8, 8, 8, 8)
    TestingFrame.iLayout:SetSpaceX(4)
    TestingFrame.iLayout:SetSpaceY(4)

    local sorted = {}
    for k, v in pairs(gifs) do
        local v = table.Copy(v)
        v.key = k

        table.insert(sorted, v)
    end

    table.SortByMember(sorted, "key", true)

    for k, v in ipairs(sorted) do
        local gifPanel = TestingFrame.iLayout:Add("SlashUI.Panel")
        gifPanel:SetSize(100, 100)
        gifPanel.Paint = function(pnl, w, h)
            SlashModules.DrawGIF(v.key, 0, 0, w, h, color_white)
        end
    end
end)