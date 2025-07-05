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
        block_count = 0,
        has_banned_blocks = false,
        banned_blocks = {},
        total_engines = 0
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

    -- Hinge having less drag is debatable because it honestly doesnt matter that much
    SmallHinge = "decoration",

    ModularTubeSystem_TubeDoubleElbow = "decoration",
    ModularTubeSystem_Skewed1x1x2 = "decoration",
    ModularTubeSystem_Tube1x1x8 = "decoration",
    ModularTubeSystem_Skewed2x1x2 = "decoration",
    ModularTubeSystem_TubeTeeCross = "decoration",
    ModularTubeSystem_DoubleCross = "decoration",
    ModularTubeSystem_Tube3x1 = "decoration",
    ModularTubeSystem_TubeDoubleTee = "decoration",
    ModularTubeSystem_Tube1x4 = "decoration",
    ModularTubeSystem_TubeTee = "decoration",
    ModularTubeSystem_Tube1x1 = "decoration",
    ModularTubeSystem_TubeElbow = "decoration",
    ModularTubeSystem_TubeCross = "decoration",
    LightFront = "decoration",
    LightFrontLarge = "decoration",
    LightFront_V2 = "decoration",
    LightBack = "decoration",
    LightBack_V2 = "decoration",
    PopupHeadlightBlock = "decoration",
    BajaLEDs = "decoration",
    CityHeadlights = "decoration",
    MilitaryHeadlights = "decoration",
    CameraBlock = "decoration",

    -- no drag for the seats
    GokartSeat = "seat",
    InputSeat = "seat",
    ArmouredSeat = "seat",
    CarSeat = "seat",

    -- if you have any ideas for other pieces to reduce or no drag feel free to put them here if they are decorative parts on your kart
    -- note to self: find a way to boost performance of bikes because they are severely underpowered

    EngineBasic = "engine",
    EngineOlSchool = "engine",
    EngineNinja = "engine",

    -- Banned blocks
    -- Banned blocks: Traction
    AnchorBlock = "banned",
    HoveringBlock = "banned",
    -- Banned blocks: Mechanical
    DetachableBlock = "banned",
    PowerConduitConnector = "banned",
    -- Banned blocks: Air propellers
    PropellerBlock = "banned",
    LargePropeller = "banned",
    HelicopterTailPropeller = "banned",
    HugePropellerEngine = "banned",
    -- Banned blocks: Water propellers
    UnderWaterPropeller = "banned",
    BulldawgBoatEngineBlock = "banned",
    -- Banned blocks: Thrusters
    JetEngineLarge = "banned",
    JetGimbal = "banned",
    JetEngine = "banned",
    -- Banned blocks: Lift
    ModularWingSmall = "banned",
    WingFlapSmall = "banned",
    ModularWing = "banned",
    AirBalloon = "banned",
    WingFlap = "banned",
    SmallBalloon = "banned",
    HeliRotator = "banned",
    HeliRotatorv2 = "banned",
    Helicopterblade = "banned",
    HelicopterBladeShort = "banned",
    HelicopterbladeLong = "banned",
    -- Banned blocks: Weapons
    AimingServo = "banned",
    EnergyShield = "banned",
    SmallEnergyShield = "banned",
    BombRack = "banned",
    Dynamite = "banned",
    Dispenser_LandMine = "banned",
    CannonTiny = "banned",
    CannonSmall = "banned",
    ShortRangeSpray = "banned",
    Shotgun = "banned",
    MiniGun = "banned",
    MiniGrenadeLauncher = "banned",
    Cannon = "banned",
    FlakCannon_Large = "banned",
    FlakCannon_Small = "banned",
    TankCannon = "banned",
    RocketLauncher = "banned",
    GunpowderCannon = "banned",
    TankCannonSmall = "banned",
    SpaceBlasterTiny = "banned",
    SpaceBlaster = "banned",
    EMPBlaster = "banned",
    ShortRangeEMPBlaster = "banned",
    Flamethrower = "banned",
    Underwater_ProjectileWeapon = "banned",
    Underwater_ExplosiveWeapon = "banned",
    Dispenser_DepthCharge = "banned",
    Dispenser_Torpedos = "banned",
    Dispenser_SeaMine = "banned"
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
        local live_block_count = 0
        local structures = tm.players.GetPlayerStructuresInBuild(playerId)
        for _, structure in ipairs(structures) do
            live_block_count = live_block_count + #structure.GetBlocks()
        end
        if live_block_count ~= player_data[playerId].block_count then
            if profiling==true then
                tm.os.Log("Build was updated for ".. tm.players.GetPlayerName(playerId).. " (".. playerId.. "), updating data...")
            end
            player_data[playerId].total_buoyancy = 0
            player_data[playerId].total_weight = 0
            player_data[playerId].has_banned_blocks = false
            player_data[playerId].banned_blocks = {}
            player_data[playerId].total_engines = 0
            for _,structure in ipairs(structures) do
                local blocks = structure.GetBlocks()
                for index,block in pairs(blocks) do
                    local value = block_types[string.sub(block.GetName(), 5, -10)]

                    if value == "banned" then
                        for _,block in ipairs(blocks) do
                            local value = block_types[string.sub(block.GetName(), 5, -10)]
                            if value == "engine" then
                                block.SetEnginePower(0)
                            end
                        end
                        player_data[playerId].has_banned_blocks = true
                        table.insert(player_data[playerId].banned_blocks, string.sub(block.GetName(), 5, -10))
                    end

                    if value == "3x3x1" or value == "3x3x2" then -- set buoyancy for common wheels
                        block.SetBuoyancy(9) -- multiply buoyancy by 5 to convert to kg
                    end
                    if value == "4x1x1" then -- skis and pistons
                        block.SetBuoyancy(32)
                        block.SetDragAll(0.1, 0.1, 0.1, 0.1, 0.1, 0.1) -- 0 drag pistons and skis
                    end
                    if value == "seat" then
                        block.SetDragAll(0.1, 0.1, 0.1, 0.1, 0.1, 0.1) -- 0 drag 
                    end
                    if value == "decoration" then -- pipes, lights, steering hinge, camera block
                        block.SetDragAll(0.1, 0.1, 0.1, 0.1, 0.1, 0.1) -- 0 drag for now, in the future make it the same as 2x1x1 wedge
                    end
                    -- Log the current engine's secondary color. Un comment this when adding new cc colors
                    --if value == "engine" then tm.os.Log(block.GetSecondaryColor().ToString()) end
                    if value == "engine" and #player_data[playerId].banned_blocks==0 then
                        block.SetEnginePower(0) -- Set to zero so if it's an invalid color it remains as zero
                        --tm.os.Log("Engine power is now 0")
                        if player_data[playerId].total_engines==0 then
                            for i,_ in pairs(engine_cc_list) do
                                if block.GetSecondaryColor().ToString()==engine_cc_list[i].color then
                                    block.SetEnginePower(engine_cc_list[i].cc*22.22)
                                    --tm.os.Log("Engine power is now ".. block.GetEnginePower())
                                    player_data[playerId].total_engines = player_data[playerId].total_engines + 1
                                end
                            end
                        else
                            player_data[playerId].total_engines = player_data[playerId].total_engines + 1
                            for _,block in ipairs(blocks) do
                                local value = block_types[string.sub(block.GetName(), 5, -10)]
                                if value == "engine" then
                                    block.SetEnginePower(0)
                                    --tm.os.Log("Engine power is now ".. block.GetEnginePower())
                                end
                            end
                        end
                    end

                    -- multiply mass by 5 to convert to kg
                    player_data[playerId].total_buoyancy = player_data[playerId].total_buoyancy + block.GetBuoyancy()*5
                    player_data[playerId].total_weight = player_data[playerId].total_weight + block.GetMass()*5
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
    local profiling_ui_start_time = tm.os.GetRealtimeSinceStartup()
    if tm.players.GetPlayerIsInBuildMode(playerId)==true then
        if player_data[playerId].has_banned_blocks==false then
        if player_data[playerId].total_engines<2 then
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
        else
            tm.playerUI.AddUILabel(playerId, "toomanyengines", "<b><color=#E22>You can only have one engine!</color></b>")
        end
        else
            tm.playerUI.AddUILabel(playerId, "banned-blocks", "<b><color=#E22>Your kart has banned blocks!</color></b>")
            for i,_ in ipairs(player_data[playerId].banned_blocks) do
                tm.playerUI.AddUILabel(playerId, "banned-blocks-"..i, "<i>".. player_data[playerId].banned_blocks[i].. "</i>")
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
