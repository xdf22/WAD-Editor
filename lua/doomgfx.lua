// TODO: faster drawing somehow

rawset(_G,"doomgfx",{})

// helper functions
local function u16(data,pos)
    return data:byte(pos) + data:byte(pos+1)*256
end

local function u32(data,pos)
    return data:byte(pos) + data:byte(pos+1)*256 +
           data:byte(pos+2)*65536 + data:byte(pos+3)*16777216
end

---decodes doomgfx data
---@param data string: doomgfx data
---@return table decoded data: {width, height, pixels}
function doomgfx.decode(data)
    local width, height = u16(data,1), u16(data,3)
    local pixels = {}

    for x = 0, width-1 do
        pixels[x] = {}
        local columnPtr = u32(data, 9 + x*4) + 1

        while true do
            local yStart = data:byte(columnPtr)
            if yStart == 255 then break end

            local length = data:byte(columnPtr+1)
            columnPtr = columnPtr + 3

            for i = 0, length-1 do
                pixels[x][yStart+i] = data:byte(columnPtr+i)
            end

            columnPtr = columnPtr + length + 1
        end
    end

    return {width = width, height = height, pixels = pixels}
end

---draws a decoded doomgfx
---@param v videolib: videolib variable
---@param patch table: decoded doomgfx from doomgfx.decode
---@param x integer: x position for drawing
---@param y integer: y position for drawing
---@param flags integer: V_ flags
function doomgfx.draw(v, patch, x, y, flags)
    local coolerDrawFill = v.drawFill
    for xPixel = 0, patch.width-1 do
        local column = patch.pixels[xPixel]
        if column then
            for yPixel, color in pairs(column) do
                coolerDrawFill(x + xPixel, y + yPixel, 1, 1, color | flags)
            end
        end
    end
end
