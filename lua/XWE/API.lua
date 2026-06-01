// instead of calling wad.open/pk3.open in GUI.lua or any other function, use callbacks that work for both files

rawset(_G, "xwe", {})

function xwe.openfile(path)
    local pk = pk3.open(path)

    if pk and pk.entries and #pk.entries > 0 then
        return pk
    end

    return wad.open(path)
end

function xwe.createfile(type)
    if type == "pk3" then
        return pk3.create()
    elseif type == "wad" then
        return wad.create("PWAD")
    end
end

function xwe.add(file, name, data)
    if not file then return end

    file.entries = file.entries or {}

    file.entries[#file.entries + 1] =
    {
        name = name,
        data = data or ""
    }
end

function xwe.remove(file, id)
    if not file or not file.entries then return end

    table.remove(file.entries, id)
end

function xwe.save(file, path)
    if not file then return false end
    if not path then return false end

    if file.type == "PK3" then
        return pk3.write(file, path)
    else // assume wad
        return wad.write(file, path)
    end
end
