// barebones pk3 support
// this took me a while to figure out so i should probably add more commenting

rawset(_G, "pk3", {})

// helper functions
local function u16(f)
    local a,b = f:read(1):byte(), f:read(1):byte()
    return a + b*256
end

local function u32(f)
    local a,b,c,d = f:read(1):byte(),f:read(1):byte(),f:read(1):byte(),f:read(1):byte()
    return a + b*256 + c*65536 + d*16777216
end

// what do you THINK "eocd" means
local function find_eocd(f)
    f:seek("end")
    local size = f:seek()

    local scan = min(size, 65536)
    f:seek("set", size - scan)

    local buf = f:read(scan)

    for i = scan - 3, 1, -1 do
        if buf:byte(i) == 0x50 and buf:byte(i+1) == 0x4B
        and buf:byte(i+2) == 0x05 and buf:byte(i+3) == 0x06 then
            return size - scan + (i - 1)
        end
    end
end

function pk3.open(path)
    local f = io.openlocal(path, "rb")
    if not f then return nil end

    local pk =
    {
        file = f,
        path = path,
        type = "PK3", // not a thing in actual pk3's, used to differentiate in XWE/API.lua
        entries = {}
    }

    local eocd = find_eocd(f)
    if not eocd then
        print("PK3 End of central directory not found")
        return pk
    end

    // total entries
    f:seek("set", eocd + 10)
    local total = u16(f)

    f:seek("set", eocd + 16)
    local cd_offset = u32(f)

    f:seek("set", cd_offset)

    for i = 1, total do
        if u32(f) ~= 0x02014b50 then
            break
        end

        f:seek("cur", 4)
        f:seek("cur", 2)

        local method = u16(f)

        f:seek("cur", 4)
        f:seek("cur", 4)

        local comp_size = u32(f)
        local uncomp_size = u32(f)

        local name_len = u16(f)
        local extra_len = u16(f)
        local comment_len = u16(f)

        f:seek("cur", 8)

        local offset = u32(f)

        local name = f:read(name_len) or ""

        f:seek("cur", extra_len + comment_len)

        pk.entries[#pk.entries+1] =
        {
            name = name,
            size = uncomp_size,
            csize = comp_size,
            offset = offset
        }
    end

    return pk
end

// 0 compression supported :grin:
function pk3.read(pk, name)
    if not pk then return end

    for _,v in ipairs(pk.entries) do
        if v.name == name then
            local f = pk.file

            f:seek("set", v.offset + 30)

            local n = u16(f)
            local e = u16(f)

            f:seek("cur", n + e)

            return f:read(v.size)
        end
    end
end

// listing, see wad.list
function pk3.list(pk, indicators)
    if not pk then return end

    for i = 1, #pk.entries do
        local entry = pk.entries[i]
        local sizeStr

        if indicators then
            if entry.size >= 1024 * 1024 then
                sizeStr = string.format("%d MB", entry.size / (1024 * 1024))
            elseif entry.size >= 1024 then
                sizeStr = string.format("%d KB", entry.size / 1024)
            else
                sizeStr = string.format("%d B", entry.size)
            end
        else
            sizeStr = tostring(entry.size)
        end

        print(string.format("[%d] %-8s, size=%s", i, entry.name, sizeStr))
    end
end

// create a pk3
function pk3.create()
    return {
        file = nil,
        entries = {}
    }
end

// create a file
function pk3.add(pk3_file, name, data)
    if not pk3_file then return end

    pk3_file.entries[#pk3_file.entries + 1] =
    {
        name = name,
        data = data,
        size = #data
    }
end

// remove a file
function pk3.remove(pk, name)
    if not pk or not pk.entries then return end

    for i = 1, #pk.entries do
        local file = pk.entries[i]
        if file and file.name == name then
            table.remove(pk.entries, i)
            return true
        end
    end

    return false
end

// write, also 0 compression
local function write_u16(f, v)
    f:write(string.char(v & 255, (v >> 8) & 255))
end

local function write_u32(f, v)
    f:write(string.char(
        v & 255,
        (v >> 8) & 255,
        (v >> 16) & 255,
        (v >> 24) & 255
    ))
end

function pk3.write(pk3_file, path)
    if not pk3_file then return false end

    local f = io.openlocal(path, "wb")
    if not f then return false end

    local offset_list = {}

    for i = 1, #pk3_file.entries do
        local entry = pk3_file.entries[i]

        offset_list[i] = f:seek()

        f:write(entry.data or "")
    end

    local central_dir_offset = f:seek()

    for i = 1, #pk3_file.entries do
        local entry = pk3_file.entries[i]
        local name = entry.name or ""

        write_u32(f, 0x02014b50)

        f:seek("cur", 6)
        write_u16(f, 0)

        f:seek("cur", 12)

        write_u32(f, entry.size or 0)
        write_u32(f, entry.size or 0)

        write_u16(f, #name)
        write_u16(f, 0)
        write_u16(f, 0)

        f:seek("cur", 8)

        write_u32(f, offset_list[i])

        f:write(name)
    end

    local end_offset = f:seek()

    write_u32(f, 0x06054b50)
    write_u16(f, 0)
    write_u16(f, 0)
    write_u16(f, #pk3_file.entries)
    write_u16(f, #pk3_file.entries)
    write_u32(f, end_offset - central_dir_offset)
    write_u32(f, central_dir_offset)
    write_u16(f, 0)

    f:close()
    return true
end

// close a pk3
function pk3.close(pk)
    if pk and pk.file then pk.file:close() end
end
