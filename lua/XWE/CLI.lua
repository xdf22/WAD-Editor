// it stands for xdf wad editor

local currentwadfile

COM_AddCommand("wad", function(player, ...)
    local args = {...}
    if not args[1] then CONS_Printf(player, "Subcommands: open, create, list, lump, write, close") return end

    // open a wad
    if args[1] == "open" then
        if not args[2] then CONS_Printf(player, "Subcommand2: File path Missing") return end
        currentwadfile = wad.open(args[2])
        print(string.format("Opened wad: %s", args[2]))

    // create a wad
    elseif args[1] == "create" then
        currentwadfile = wad.create("PWAD")
        print("Created new wad")

    // list the entries of a wad
    elseif args[1] == "list" then
        wad.list(currentwadfile, true)

    // lump based subcommands
    elseif args[1] == "lump" then
        if not args[2] then CONS_Printf(player, "Subcommands: create, data, name, export, import") return end

        // create a new lump
        if args[2] == "create" then
            if not args[3] then CONS_Printf(player, "Subcommand3: Lump Name Missing") return end
            wad.addlump(currentwadfile, args[3], "")
            print(string.format("Created lump %d: %s", currentwadfile.numlumps, args[3]))

        // modify the data of a lump index
        elseif args[2] == "data" then
            if not args[3] then CONS_Printf(player, "Subcommand3: Lump index Missing") return end
            if not args[4] then CONS_Printf(player, "Subcommand4: Lump Data Missing") return end
            currentwadfile.entries[tonumber(args[3])].data = args[4]
            print(string.format("Modified lump %d: %s", tonumber(args[3]), currentwadfile.entries[tonumber(args[3])].name))

        // modify the name of a lump index
        elseif args[2] == "name" then
            if not args[3] then CONS_Printf(player, "Subcommand3: Lump index Missing") return end
            if not args[4] then CONS_Printf(player, "Subcommand4: Lump Name Missing") return end
            currentwadfile.entries[tonumber(args[3])].name = args[4]
            print(string.format("Modified lump %d: %s", tonumber(args[3]), currentwadfile.entries[tonumber(args[3])].name))

        // exports a lump's data to a specific path
        elseif args[2] == "export" then
            if not args[3] then CONS_Printf(player, "Subcommand3: Lump index Missing") return end
            if not args[4] then CONS_Printf(player, "Subcommand4: Output Path Missing") return end
            local f = io.openlocal(args[4], "w")
            if not f then return end
            f:write(currentwadfile.entries[tonumber(args[3])].data)
            f:close()
            print(string.format("Exported lump %d: %s", tonumber(args[3]), currentwadfile.entries[tonumber(args[3])].name))

        // replaces the lump's data with a file's data
        elseif args[2] == "import" then
            if not args[3] then CONS_Printf(player, "Subcommand3: Lump index Missing") return end
            if not args[4] then CONS_Printf(player, "Subcommand4: Input Path Missing") return end
            local f = io.openlocal(args[4], "rb")
            if not f then return end
            currentwadfile.entries[tonumber(args[3])].data = f:read("a")
            f:close() 
            print(string.format("Exported lump %d: %s", tonumber(args[3]), currentwadfile.entries[tonumber(args[3])].name))
        end

    // writes changes
    elseif args[1] == "write" then
        if not args[2] then CONS_Printf(player, "Subcommand2: Output Path Missing") return end
        wad.write(currentwadfile, args[2])
        print(string.format("Wrote %d lumps to wad file: luafiles/%s", currentwadfile.numlumps, args[2]))

    // closes a wad
    elseif args[1] == "close" then
        wad.close(currentwadfile)
    end
end)
