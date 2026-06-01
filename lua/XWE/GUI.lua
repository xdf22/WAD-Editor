// WIP
// used to directly use wad.XX functions until i added pk3 support
// see API.lua

local prevMouseButtons = 0

local currentwadfile
local selectedlump = 1
local previewEditing = false
local lumpScroll, previewScroll = 0, 0

local wadPath = ""
local wadPathEditing = false

local filePath = ""
local filePathEditing = false

local searchText = ""
local searchEditing = false
local filteredLumps = {}

local folderOpen = {}

local UI =
{
    bg=5, dark=0, panel=7, border=31,
    title=153, hover=9, select=11
}

local function getCursorPos(v)
    local x,y = input.getCursorPosition()
    return x/v.dupx(), y/v.dupy()
end


local function updateSearch()
    filteredLumps = {}

    if not currentwadfile then return end

    for i,e in ipairs(currentwadfile.entries) do
        if searchText == ""
        or e.name:lower():find(searchText:lower(), 1, true)
        then
            filteredLumps[#filteredLumps+1] = i
        end
    end
end

// todo, combine these
local function openWad()
    if wadPath == "" then return end

    local f = io.openlocal(wadPath, "rb")
    if not f then
        print("WAD not found:", wadPath)
        return
    end
    f:close()

    currentwadfile = xwe.openfile(wadPath)
    selectedlump = 1
    updateSearch()
end

local function drawPathBar(v)
    local x, y, w, h = 4, 44, 312, 14

    local mx,my = getCursorPos(v)
    local hover = mx>=x and mx<=x+w and my>=y and my<=y+h

    v.drawFill(x, y, w, h, UI.dark|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawFill(x, y, w, 1, UI.border|V_SNAPTOTOP|V_SNAPTOLEFT)

    if wadPathEditing or hover then
        v.drawFill(x, y, w, h, UI.panel|V_SNAPTOTOP|V_SNAPTOLEFT)
    end

    local text = wadPath ~= "" and wadPath or "Enter path to WAD file:"

    v.drawString(x+4, y+3, text:sub(1, 50), V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE, "thin")

    if hover and mouse.buttons & MB_BUTTON1 then
        wadPathEditing = true
    elseif mouse.buttons & MB_BUTTON2 and hover then
        openWad()
    end
end

local function importFile()
    if filePath == "" then return end

    local f = io.openlocal(filePath, "rb")
    if not f then
        print("File not found:", filePath)
        return
    end

    currentwadfile.entries[selectedlump].data = f:read("*a")
    f:close()
    filePathEditing = false
    updateSearch()
end

local function drawImportPathBar(v)
    local x, y, w, h = 4, 44, 312, 14

    local mx,my = getCursorPos(v)
    local hover = mx>=x and mx<=x+w and my>=y and my<=y+h

    v.drawFill(x, y, w, h, UI.dark|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawFill(x, y, w, 1, UI.border|V_SNAPTOTOP|V_SNAPTOLEFT)

    if filePathEditing or hover then
        v.drawFill(x, y, w, h, UI.panel|V_SNAPTOTOP|V_SNAPTOLEFT)
    end

    local text = filePath ~= "" and filePath or "Enter path to imported file:"

    v.drawString(x+4, y+3, text:sub(1, 50), V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE, "thin")

    if hover and mouse.buttons & MB_BUTTON1 then
        filePathEditing = true
    elseif mouse.buttons & MB_BUTTON2 and hover then
        importFile()
    end
end

local function drawPanel(v,x,y,w,h, flags)
    v.drawFill(x-1,y-1,w+2,h+2,UI.border|V_SNAPTOTOP|flags)
    v.drawFill(x,y,w,h,UI.dark|V_SNAPTOTOP|flags)
end

local function drawButton(v,x,y,patch,text,func)
    local mx,my = getCursorPos(v)
    local hover = mx>=x and mx<=x+44 and my>=y and my<=y+20

    v.drawFill(x,y,44,20,(hover and UI.hover or UI.panel)|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawScaled((x+2)*FU,(y+2)*FU,FU/2,v.cachePatch(patch),V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawString(x+18,y+6,text,V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE|V_MONOSPACE)

    local wasClick = (mouse.buttons & MB_BUTTON1) and (prevMouseButtons & MB_BUTTON1) == 0

    if hover and wasClick then prevMouseButtons = mouse.buttons; func() end
end

local function drawWindow(v)
    v.drawFill(0,0,320,200,UI.bg|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawFill(0,0,400,16,UI.title|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawFill(0,16,400,24,UI.panel|V_SNAPTOTOP|V_SNAPTOLEFT)

    v.drawScaled(2*FU,1*FU,FU/2,v.cachePatch("M_FWAD"),V_SNAPTOTOP|V_SNAPTOLEFT)

    v.drawString(18,4, string.format("%s - xdf Wad Editor!", currentwadfile and currentwadfile.path or "No file"), V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE)
end

local function drawToolbar(v)
    drawButton(v,4,18,"M_FYEAH","NEW",function()
        currentwadfile = xwe.createfile("PWAD")
        updateSearch()
        currentwadfile.path = "Unsaved Wad"
        S_StartSound(nil, sfx_addfil)
    end)

    drawButton(v,50,18,"M_FSAVE","SAVE",function()
        if currentwadfile then xwe.write(currentwadfile,"new.wad.txt") S_StartSound(nil, sfx_strpst) end
    end)

    drawButton(v,170,18,"M_FYEAH","ADD",function()
        if currentwadfile then xwe.add(currentwadfile,"TEST","") S_StartSound(nil, sfx_radio) end
    end)

    drawButton(v,220,18,"M_FNOPE","DEL",function()
        if currentwadfile then wad.removelump(currentwadfile) S_StartSound(nil, sfx_pop) end
    end)

    drawButton(v,270,18,"M_FSAVE","EXP",function()
        if currentwadfile then
            local f = io.openlocal((currentwadfile.entries[selectedlump].name)+".txt", "wb")
            if f == nil then return end
            f:write(currentwadfile.entries[selectedlump].data)
            f:close()
            S_StartSound(nil, sfx_strpst)
        end
    end)

    drawButton(v,320,18,"M_FFLDR","IMP",function()
        filePathEditing = true
    end)
end


local function isGraphic(data)
    if not data or #data < 8 then return false end

    local w = data:byte(1) + data:byte(2)*256
    local h = data:byte(3) + data:byte(4)*256

    return w > 0 and w < 1024
    and h > 0 and h < 1024
end

local function drawLumpList(v)
    if not currentwadfile then return end

    if #filteredLumps == 0 then
        updateSearch()
    end

    local mx,my = getCursorPos(v)

    local x,y,w,h = 4,50,110,140
    local rowh = 8

    drawPanel(v,x,y,w,h,V_SNAPTOLEFT)

    v.drawFill(x,y,w,12, UI.panel|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawString(x+4,y+2, "LUMPS", V_SNAPTOTOP|V_SNAPTOLEFT)

    // search (bar)
    local sx,sy,sw,sh = x+2,y+14,w-4,10

    v.drawFill(sx,sy,sw,sh, (searchEditing and UI.select or UI.dark)|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawFill(sx,sy+sh-1,sw,1, UI.border|V_SNAPTOTOP|V_SNAPTOLEFT)
    v.drawString(sx+2,sy+2, searchText ~= "" and searchText or "search lumps...", V_ALLOWLOWERCASE|V_SNAPTOTOP|V_SNAPTOLEFT, "thin")

    // search hover detection
    if mouse.buttons & MB_BUTTON1 then
        searchEditing = mx>=sx and mx<=sx+sw and my>=sy and my<=sy+sh
    end

    // the actual listing
    local listY = sy + sh + 4
    local visible = 14

    local maxScroll = max(0,#filteredLumps-visible)
    lumpScroll = max(0,min(lumpScroll,maxScroll))

    local drawn = 0

    for i=1,visible do
        local listid = i + lumpScroll
        local id = filteredLumps[listid]

        if not id then break end

        local e = currentwadfile.entries[id]
        if not e then break end

        local isFolder = e.name:sub(-1) == "/"
        local folder = e.name:match("^(.-)/")

        if not (folder and folderOpen[folder] == false and not isFolder) then
            local yy = listY + drawn * rowh

            local hover =
                mx>=x and mx<=x+w
                and my>=yy and my<=yy+rowh

            // hover
            if hover then
                v.drawFill(x,yy,w,rowh, UI.hover|V_SNAPTOTOP|V_SNAPTOLEFT)
            end

            if selectedlump == id then
                v.drawFill(x,yy,w,rowh, UI.select|V_SNAPTOTOP|V_SNAPTOLEFT)
            end

            // entry icon
            local icon = "M_FTXT"

            if isFolder then
                icon = "M_FFLDR"
            elseif e.name:find("LUA_") or e.name:find(".lua") then
                icon = "M_FLUA"
            elseif e.name:find("SOC_") or e.name:find(".soc") then
                icon = "M_FSOC"
            elseif isGraphic(e.data) then
                icon = "M_IMG"
            elseif e.name:find("_START") or e.name:find("_END") then
                icon = "M_MARK"
            end

            v.drawScaled((x+2)*FU, (yy+1)*FU, FU/5, v.cachePatch(icon), V_SNAPTOTOP|V_SNAPTOLEFT)

            // file name
            v.drawString(x+10,yy, e.name:sub(1,14), V_SNAPTOTOP|V_SNAPTOLEFT|V_ALLOWLOWERCASE, "thin")

            // click
            local wasClick = (mouse.buttons & MB_BUTTON1) and (prevMouseButtons & MB_BUTTON1) == 0

            if hover and wasClick then
                if isFolder then
                    local key = e.name:sub(1, -2) -- remove "/"
                    folderOpen[key] = not folderOpen[key]
                else
                    selectedlump = id
                end
            end

            drawn = drawn + 1
        end

        i = i + 1
    end

    // scroll
    local bx,by,bh = x+w-3,listY,h-(listY-y)

    v.drawFill(bx,by,3,bh, UI.panel|V_SNAPTOTOP|V_SNAPTOLEFT)

    if #filteredLumps > visible then
        local size = max(10,(visible/#filteredLumps)*bh)
        local pos = (lumpScroll*(bh-size))/(#filteredLumps-visible)

        v.drawFill(bx,by+pos,3,size, UI.border|V_SNAPTOTOP|V_SNAPTOLEFT)
    end

    prevMouseButtons = mouse.buttons
end

local function drawPreview(v)
    if not currentwadfile then return end

    local e = currentwadfile.entries[selectedlump]
    if not e then return end

    local mx,my = getCursorPos(v)
    local x,y,w,h = 120,50,190,140

    local text = ""

    drawPanel(v,x,y,w,h,V_SNAPTORIGHT)

    v.drawFill(x,y,w,18,
        UI.panel|V_SNAPTOTOP|V_SNAPTORIGHT)

    v.drawString(x+4,y+4,e.name,
        V_SNAPTOTOP|V_SNAPTORIGHT)

    // preview for graphics
    if isGraphic(e.data) then
        local gfx = doomgfx.decode(e.data)

        local drawx = x + (w - gfx.width) / 2
        local drawy = y + 18 + ((h - 18 - gfx.height) / 2)

        doomgfx.draw(v, gfx, drawx, drawy, V_SNAPTOTOP|V_SNAPTORIGHT)
        return
    end

    // preview for text
    local lines = {}

    for s in ((e.data or "").."\n"):gmatch("(.-)\r?\n") do
        lines[#lines+1] = s:gsub("\t","    ")
    end

    local vh = 14

    previewScroll =
        max(0,min(previewScroll,max(0,#lines-vh)))

    local tx,ty,lh = x+4,y+22,8

    for i=1,vh do
        text = lines[i+previewScroll]
        if not text then break end

        v.drawString(tx, ty+(i-1)*lh, text:sub(1,36), V_ALLOWLOWERCASE|V_SNAPTOTOP|V_SNAPTORIGHT, "thin")
    end

    // scroll bar
    local bx,by,bh = x+w-3,ty,h-22

    v.drawFill(bx,by,3,bh, UI.panel|V_SNAPTOTOP|V_SNAPTORIGHT)

    if #lines > vh then
        local size = max(10,(vh/#lines)*bh)
        local pos = (previewScroll*(bh-size))/(#lines-vh)

        v.drawFill(bx,by+pos,3,size, UI.border|V_SNAPTOTOP|V_SNAPTORIGHT)
    end

    // enable editing
    if mouse.buttons & MB_BUTTON1 then
        previewEditing =
            mx>=x and mx<=x+w
            and my>=y and my<=y+h
    end

    // the I-Beam (needs better way to detect line length)
    if previewEditing and (leveltime%20<10) then
        if not text then return end

        v.drawFill(v.stringWidth(text:sub(1,36)), ty+((#lines-1-previewScroll)*lh), 1,lh, UI.border|V_SNAPTOTOP|V_SNAPTORIGHT)
    end
end

// typing
addHook("KeyDown", function(key)
    // wad path
    if wadPathEditing then
        if key.num == 8 then
            wadPath = wadPath:sub(1, -2)

        elseif key.num == 13 then
            wadPathEditing = false
            openWad()

        elseif key.num >= 32 and key.num <= 126 then
            wadPath = wadPath .. string.char(key.num)
        end

        return true
    end

    if filePathEditing then
        if key.num == 8 then
            filePath = filePath:sub(1, -2)

        elseif key.num == 13 then
            filePathEditing = false
            importFile()

        elseif key.num >= 32 and key.num <= 126 then
            filePath = filePath .. string.char(key.num)
        end

        return true
    end

    // search
    if searchEditing then
        if key.num == 8 then
            searchText = searchText:sub(1,-2)

        elseif key.num >= 32
        and key.num <= 126 then
            searchText = searchText .. string.char(key.num)
        end

        updateSearch()
        return
    end

    // text editor
    if not previewEditing or not currentwadfile then
        return
    end

    local e = currentwadfile.entries[selectedlump]
    if not e then return end

    e.data = e.data or ""

    if key.num==8 then
        e.data=e.data:sub(1,-2)

    elseif key.num==13 then
        e.data=e.data.."\n"

    elseif key.num==9 then
        e.data=e.data.."    "

    elseif key.num>=32 and key.num<=126 then
        e.data=e.data..string.char(key.num)
    end

    return true
end)

local function inRect(x,y,w,h,mx,my)
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end

addHook("HUD", function(v)
    input.setMouseGrab(false)
    local mx,my = getCursorPos(v)

    drawWindow(v)
    drawToolbar(v)
    if not filePathEditing then
        drawLumpList(v)
        drawPreview(v)
    end

    if filePathEditing then
        drawImportPathBar(v)
    end

    if not currentwadfile then
        drawPathBar(v)
    end

    if mouse.buttons & MB_SCROLLUP then
        if inRect(4,44,110,140,mx,my) then
            lumpScroll = lumpScroll - 1
        else
            previewScroll = previewScroll - 1
        end
    elseif mouse.buttons & MB_SCROLLDOWN then
        if inRect(4,44,110,140,mx,my) then
            lumpScroll = lumpScroll + 1
        else
            previewScroll = previewScroll + 1
        end
    end

    if VERSIONSTRING == "v2.2.13" then
        v.drawFill(0, 0, 320, 200, 31)
        local stringe = "This addon is not supported on Android."
        v.drawString(160-(v.stringWidth(stringe)/2), 100, stringe)
    end
end,"game")

addHook("MapLoad", function() S_ChangeMusic("EDITOR", true) end)
