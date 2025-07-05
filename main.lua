tm.os.Log("KartMakers by HormaV5 (Project lead), RainlessSky (Programmer), Antimatterdev (Fake programmer)")

-- Enable performance logging
local profiling = false

local profiling_structure_checking_time = 0
local profiling_ui_time = 0
local profiling_mod_start_time = 0

-- Multiplier for cc. Default is 150. Edit with multiples of 50
local engine_cc = 150

player_data = {}
function OnPlayerJoined(player)
    player_data[player.playerId] = {
        total_buoyancy = 0,
        total_weight = 0,
        block_count = 0
    }
end
tm.players.OnPlayerJoined.add(OnPlayerJoined)

local block_types = {
    -- Wheels and their dimensions. Affects buoyancy.
    WheelStandard = "3x3x2",
    WheelSlick = "3x3x2",
    MonsterTruckWheelBlock = "7x7x4",
    GocartWheel = "2x2x1",
    SlimWheel = "3x3x1",
    DragRacingWheel = "5x5x4",
    TruckWheel = "5x5x2",
    SpikedWheel = "3x3x2",
    CarWheel_3x3x1 = "3x3x1",
    MotorCycleWheel = "3x3x1",
    TopMountedLandingWheel = "3x2x2",
    WaterSki = "4x1x1",
    Piston = "4x1x1",

    -- Hinge having no drag is debatable because it honestly doesnt matter that much
    SmallHinge = "decoration",

    -- pipes suck for aerodynamics as decoration pieces but if rainless is reading this,
    -- the intention is for pipes to have the same drag as 2x1x1 wedges
    -- however i have no clue how much drag it has so for now it will be zero drag
    ModularTubeSystem_Tube1 = "decoration",
    ModularTubeSystem_Skewe = "decoration",
    ModularTubeSystem_TubeE = "decoration",
    ModularTubeSystem_Tube3 = "decoration",
    LightFront = "decoration",
    LightFront_V2 = "decoration",
    PopupHeadlightBlock = "decoration",
    MilitaryHeadlights = "decoration",
    CityHeadlights = "decoration",
    BajaLEDs = "decoration",
    CameraBlock = "decoration",

    -- no drag for the seats
    GokartSeat = "seat",
    InputSeat = "seat",
    ArmouredSeat = "seat",
    CarSeat = "seat",

    -- if you have any ideas for other pieces to reduce or no drag feel free to put them here if they are decorative parts on your kart
    -- note to self: find a way to boost performance of bikes because they are severely underpowered

    EngineNinja = "engine"
}

local special_properties = { -- this is for displaying special properties on ui. labels CANNOT be >64 bytes because the server WILL CRASH
    {key="3x3x1", label="<color=#FC4>+45kg Buoyancy</color>"},
    {key="3x3x2", label="<color=#FC4>+45kg Buoyancy</color>"},
    {key="4x1x1", label="<color=#FC4>+160kg Buoyancy, 0 drag</color>"},
    {key="decoration", label="<color=#FC4>0 drag</color>"},
    {key="seat", label="<color=#FC4>0 drag</color>"},

    {key="engine", label="<color=#FC4>Read UI for Power statistic</color>"},
}
local engine_cc_list = { -- this holds the RGB color for paints, and then what engine cc they corrospond to. cc is multiplied by 22.22 when setting engine power. increase cc by multiples of 50 for clean engine power values
    {color="RGBA(1.000, 0.341, 0.133, 1.000)", cc=50},
    {color="RGBA(0.902, 0.000, 0.000, 1.000)", cc=100},
    {color="RGBA(0.741, 0.110, 0.110, 1.000)", cc=150},
    {color="RGBA(0.443, 0.000, 0.000, 1.000)", cc=200}
}

function update()
    if profiling==true then profiling_mod_start_time = tm.os.GetRealtimeSinceStartup() profiling_structure_checking_time = 0 profiling_ui_time = 0 end

    local players = tm.players.CurrentPlayers()
    for _, player in ipairs(players) do
        local playerId = player.playerId
        tm.playerUI.ClearUI(playerId)
        CheckStructures(playerId)
        UpdateUI(playerId)

        -- Proof-of-concept for per-player no-gravity toggle (it doesnt work perfectly)
        if tm.players.IsPlayerInSeat(playerId) then
            if player_data[playerId].totalweight ~= nil then
                --tm.players.GetPlayerSeatBlock(playerId).GetStructure().AddForce(0, player_data[playerId].totalweight * 14, 0)
            end
        end
    end

    if profiling==true then
        PrintProfilingData(tm.os.GetRealtimeSinceStartup())
    end
end

function CheckStructures(playerId)
    local profiling_structure_checking_start_time = tm.os.GetRealtimeSinceStartup()
    if tm.players.GetPlayerIsInBuildMode(playerId) then
        local live_block_count = -1
        local structures = tm.players.GetPlayerStructuresInBuild(playerId)
        for _, structure in ipairs(structures) do
            live_block_count = live_block_count + #structure.GetBlocks()
        end
        if live_block_count ~= player_data[playerId].block_count then
            player_data[playerId].total_buoyancy = 0
            player_data[playerId].total_weight = 0
            for _, structure in ipairs(structures) do
                local blocks = structure.GetBlocks()
                if profiling==true then
                    tm.os.Log("Build has been updated for ".. tm.players.GetPlayerName(playerId).. " (".. playerId.. "), updating data...")
                end
                for _, block in ipairs(blocks) do
                    if block.Exists() == true then
                        -- multiply mass by 5 to convert to kg
                        player_data[playerId].total_buoyancy = player_data[playerId].total_buoyancy + block.GetBuoyancy()*5
                        player_data[playerId].total_weight = player_data[playerId].total_weight + block.GetMass()*5

                        local value = block_types[string.sub(block.GetName(), 5, -10)]
                        if value == "3x3x1" or value == "3x3x2" then -- set buoyancy for common wheels
                            block.SetBuoyancy(9) -- multiply buoyancy by 5 to convert to kg
                        end
                        if value == "4x1x1" then -- skis and pistons
                            block.SetBuoyancy(32)
                            block.SetDragAll(0, 0, 0, 0, 0, 0) -- 0 drag pistons and skis
                        end
                        if value == "seat" then
                            block.SetDragAll(0, 0, 0, 0, 0, 0) -- 0 drag 
                        end
                        if value == "decoration" then -- pipes, lights, steering hinge, camera block
                            block.SetDragAll(0, 0, 0, 0, 0, 0) -- 0 drag for now, in the future make it the same as 2x1x1 wedge
                        end
                        -- Log the current engine's secondary color. Un comment this when adding new cc colors
                        --if value == "engine" then tm.os.Log(block.GetSecondaryColor().ToString()) end
                        if value == "engine" then
                            block.SetEnginePower(0) -- Set to zero so if it's an invalid color it remains as zero
                            for i,_ in pairs(engine_cc_list) do
                                if block.GetSecondaryColor().ToString()==engine_cc_list[i].color then
                                    block.SetEnginePower(engine_cc_list[i].cc*22.22)
                                    break 
                                end
                            end
                        end
                    end
                end
            player_data[playerId].block_count = #blocks
            end
        end
        if profiling==true then
            profiling_structure_checking_time = profiling_structure_checking_time + tm.os.GetRealtimeSinceStartup()-profiling_structure_checking_start_time
        end
    end
end

function UpdateUI(playerId)
    if tm.players.GetPlayerIsInBuildMode(playerId)==true then
        local profiling_ui_start_time = tm.os.GetRealtimeSinceStartup()
        tm.playerUI.AddUILabel(playerId, "totalbuoyancy", string.format("%.1f", player_data[playerId].total_buoyancy).. "kg total vehicle buoyancy")
        tm.playerUI.AddUILabel(playerId, "totalweight", string.format("%.1f", player_data[playerId].total_weight).. "kg total vehicle weight") -- Inaccurate vehicle weight isn't a bug; steering hinge has a misleading in-game weight value

        if tm.players.GetPlayerSelectBlockInBuild(playerId)~=nil then
            tm.playerUI.AddUILabel(playerId, "spacer", "")
            tm.playerUI.AddUILabel(playerId, "selectedblock-name", "".. string.sub(tm.players.GetPlayerSelectBlockInBuild(playerId).GetName(), 5, -10).. "")

            -- Get hex code of the selected block's primary color
            local color = tm.players.GetPlayerSelectBlockInBuild(playerId).GetPrimaryColor()
            local prhex = string.format("%x", color.R() * 255) -- ai told me how to do this
            local pghex = string.format("%x", color.G() * 255)
            local pbhex = string.format("%x", color.B() * 255)
            if prhex=="0" then prhex = "00" end -- fix missing zero so color preview works
            if pghex=="0" then pghex = "00" end
            if pbhex=="0" then pbhex = "00" end

            -- Get hex code of the selected block's secondary color
            local color = tm.players.GetPlayerSelectBlockInBuild(playerId).GetSecondaryColor()
            local srhex = string.format("%x", color.R() * 255) -- ai told me how to do this
            local sghex = string.format("%x", color.G() * 255)
            local sbhex = string.format("%x", color.B() * 255)
            if srhex=="0" then srhex = "00" end -- fix missing zero so color preview works
            if sghex=="0" then sghex = "00" end
            if sbhex=="0" then sbhex = "00" end

            -- Primary color display is disabled due to prevent UI flickering.
            --tm.playerUI.AddUILabel(playerId, "selectedblock-pcolor", "Primary color: <color=#".. prhex.. pghex.. pbhex.. ">██</color> #".. prhex.. pghex.. pbhex)
            tm.playerUI.AddUILabel(playerId, "selectedblock-scolor", "Secondary color: <color=#".. srhex.. sghex.. sbhex.. ">██</color> #".. srhex.. sghex.. sbhex)
            tm.playerUI.AddUILabel(playerId, "selectedblock-mass", "Weight: ".. math.floor(tm.players.GetPlayerSelectBlockInBuild(playerId).GetMass()*500)/100 .. "kg")
            tm.playerUI.AddUILabel(playerId, "selectedblock-buoyancy", "Buoyancy: ".. math.floor(tm.players.GetPlayerSelectBlockInBuild(playerId).GetBuoyancy()*500)/100 .. "kg")

            if tm.players.GetPlayerSelectBlockInBuild(playerId).IsEngineBlock() then
                if tm.players.GetPlayerSelectBlockInBuild(playerId).GetEnginePower() ~= 0 then
                    tm.playerUI.AddUILabel(playerId, "selectedblock-enginepower", tm.players.GetPlayerSelectBlockInBuild(playerId).GetEnginePower()/22.22 .. "cc | ".. tm.players.GetPlayerSelectBlockInBuild(playerId).GetEnginePower().. " power")
                else
                    tm.playerUI.AddUILabel(playerId, "selectedblock-enginepower", "<color=#FAA>Invalid secondary color!</color>") 
                end
            end
        end
        if profiling==true then
            local endtime = tm.os.GetRealtimeSinceStartup()
            profiling_ui_time = profiling_ui_time + endtime-profiling_ui_start_time
        end
    end
end

function PrintProfilingData(profiling_mod_end_time)
    if profiling_structure_checking_time~=0 then
        tm.os.Log(" ".. string.format("%0.4s", profiling_structure_checking_time*1000) .. " ms for structure checking")
    else
        tm.os.Log("<0.01 ms for structure checking")
    end
    if profiling_ui_time~=0 then
        tm.os.Log(" ".. string.format("%0.4s", profiling_ui_time*1000) .. " ms for ui")
    else
        tm.os.Log("<0.01 ms for ui")
    end
    local overhead = (profiling_mod_end_time-profiling_mod_start_time)-(profiling_structure_checking_time+profiling_ui_time)
    if overhead~=0 then
        tm.os.Log(" ".. string.format("%0.4s", overhead*1000) .. " ms overhead")
    else
        tm.os.Log("<0.01 ms for overhead")
    end
    if (profiling_mod_end_time-profiling_mod_start_time)*1000~=0 then
        tm.os.Log(" ".. string.format("%0.4s", (profiling_mod_end_time-profiling_mod_start_time)*1000) .. " ms for update()")
    else
        tm.os.Log("<0.01 ms for update()")
    end
    tm.os.Log("")
end
