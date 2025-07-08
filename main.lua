tm.os.Log("KartMakers by HormaV5 (Project lead), RainlessSky (Programmer), Antimatterdev (Fake programmer)")
tm.os.Log("")

tm.physics.AddTexture("KartOutline.png", "icon")

tm.os.SetModTargetDeltaTime(1/60)

-- Enable performance logging. 0 = off, 1 = all, 2 = limited
local profiling = 0

local profiling_structure_checking_time = 0
local profiling_ui_time = 0
local profiling_local_gravity_time = 0
local profiling_mod_start_time = 0

-- Config
local local_gravity = false -- Toggle Local Gravity on/off
local local_gravity_magnet_fling_duration = 1.5 -- How long the magnet fling lasts for (seconds) | Default: 1.5
local local_gravity_magnet_fling_strength = 2 -- Strength for magnet fling | Default: 2
local motorcycle_buff = 400 -- How much of a power increase should motorcycles get? | Default: 400

player_data = {}
function OnPlayerJoined(player)
    player_data[player.playerId] = {
        total_buoyancy = 0,
        total_weight = 0,
        block_count = 0,
        has_banned_blocks = false,
        banned_blocks = {},
        total_engines = 0,
        wheels = {
            {type="3x3x1",amount=0},
            {type="3x3x2",amount=0}
        },
        selected_engine_cc = 0,
        engines = {},
        HasGroundContact = true,
        magnet_duration = 0,
        ui_visible = false,
        banned_blocks_ui_size = 0
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
--tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Subtle message icon test", 10, "icon")

if local_gravity==true then tm.physics.SetGravityMultiplier(0) tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Playing with Local Gravity", 3, "icon") end

function ClearUIWindow(playerId)
    tm.playerUI.RemoveUI(playerId, "error.banned_blocks")
    tm.playerUI.RemoveUI(playerId, "error.too_many_engines")
    tm.playerUI.RemoveUI(playerId, "selected_block.engine_power")
    tm.playerUI.RemoveUI(playerId, "selected_block.buoyancy")
    tm.playerUI.RemoveUI(playerId, "selected_block.mass")
    tm.playerUI.RemoveUI(playerId, "selected_block.secondary_color")
    tm.playerUI.RemoveUI(playerId, "selected_block.name")
    tm.playerUI.RemoveUI(playerId, "newline")
    tm.playerUI.RemoveUI(playerId, "total_weight")
    tm.playerUI.RemoveUI(playerId, "total_buoyancy")
    for i = 0,player_data[playerId].banned_blocks_ui_size do
        tm.playerUI.RemoveUI(playerId, "error.banned_blocks-".. i)
    end
end

function update()
    if profiling==1 then profiling_mod_start_time = tm.os.GetRealtimeSinceStartup() profiling_structure_checking_time = 0 profiling_ui_time = 0 profiling_local_gravity_time = 0 end

    local players = tm.players.CurrentPlayers()
    for _, player in ipairs(players) do
        local playerId = player.playerId
        CheckStructures(playerId)
        UpdateUI(playerId)

        -- Proof-of-concept for per-player no-gravity toggle (it doesnt work perfectly)
        if local_gravity==true then ApplyLocalGravity(playerId) end
    end

    if profiling==1 then PrintProfilingData(tm.os.GetRealtimeSinceStartup()) end
end

function ApplyLocalGravity(playerId)
    local profiling_local_gravity_start_time = tm.os.GetRealtimeSinceStartup()
    -- Check if player is in a seat
    if not tm.players.IsPlayerInSeat(playerId) then return end

    local seatBlock = tm.players.GetPlayerSeatBlock(playerId)

    local structure = seatBlock.GetStructure()

    local weight = player_data[playerId] and player_data[playerId].total_weight
    if not weight then return "Structure weight is invalid" end

    local worldFront = seatBlock.Forward() -- rotated downward vector should be rotated local to player
    local worldDown = seatBlock.TransformDirection(tm.vector3.Create(0, -1, 0)) -- rotated downward vector should be rotated local to player
    local worldMagnet = tm.vector3.Lerp(worldFront, worldDown, 0.5)

    local origin = seatBlock.GetPosition()
    local rayLength = 3
    local rayEnd = origin + (worldDown * rayLength)

    local hit = tm.physics.RaycastData(origin, worldDown, rayLength, false)

    local deltatime = (60*tm.os.GetModDeltaTime())
    local gravityStrength = weight * 0.055 * deltatime

    local local_gravity_magnet_fling_duration = local_gravity_magnet_fling_duration * 60

    if hit and hit.DidHit() then
        local hitNormal = hit.GetHitNormal()

        --tm.os.Log("Ground normal: " .. tostring(hitNormal))
        -- 0.33
        structure.AddForce(worldDown.x * gravityStrength, worldDown.y * gravityStrength, worldDown.z * gravityStrength)
        player_data[playerId].HasGroundContact = true
        if player_data[playerId].magnet_duration > 0 then
            player_data[playerId].magnet_duration = 0
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Stop", tm.players.GetPlayerGameObject(playerId))
        end
    else
        if player_data[playerId].HasGroundContact==true then
            player_data[playerId].magnet_duration = local_gravity_magnet_fling_duration -- Duration in mod updates (60 = 1 second) magnet fling lasts for
            if profiling>0 then tm.os.Log(tm.players.GetPlayerName(playerId).. " got magnet fling") end
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Start", tm.players.GetPlayerGameObject(playerId))
        else
            structure.AddForce(0, -gravityStrength, 0)
        end
        player_data[playerId].HasGroundContact = false
    end

    if player_data[playerId].magnet_duration > 0 then
        local magnet_remaining = player_data[playerId].magnet_duration / local_gravity_magnet_fling_duration
        local a = magnet_remaining
        local b = a^2
        local easing = b/(2*(b-a)+1) -- Ease in/out, probably
        local multiplier = gravityStrength * easing*local_gravity_magnet_fling_strength

        --tm.os.Log(tm.players.GetPlayerName(playerId).. " currently has ".. string.format("%0.1f", player_data[playerId].magnet_duration/60) .. " seconds magnet duration left @ ".. string.format("%0.1f", easing*100) .. "%")

        local worldMagnet = tm.vector3.Lerp(seatBlock.Forward(), seatBlock.TransformDirection(tm.vector3.Create(0, -1, 0)), magnet_remaining) -- Switch "magnet_remaining" to "easing" to use ease in/out instead of linear
        structure.AddForce(worldMagnet.x * multiplier, worldMagnet.y * multiplier, worldMagnet.z * multiplier)
        
        player_data[playerId].magnet_duration = player_data[playerId].magnet_duration - 1
        if player_data[playerId].magnet_duration==0 then
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Stop", tm.players.GetPlayerGameObject(playerId))
        end
    end

    if profiling==1 then
        profiling_local_gravity_time = profiling_local_gravity_time + tm.os.GetRealtimeSinceStartup()-profiling_local_gravity_start_time
    end
end

function CheckStructures(playerId)
    local profiling_structure_checking_start_time = tm.os.GetRealtimeSinceStartup()
    if tm.players.GetPlayerIsInBuildMode(playerId) then
        local live_block_count = 0
        local structures = tm.players.GetPlayerStructuresInBuild(playerId)
        for _,structure in ipairs(structures) do
            live_block_count = live_block_count + #structure.GetBlocks()
        end
        if player_data[playerId].has_banned_blocks==false and #player_data[playerId].engines<2 then
            for i,_ in ipairs(player_data[playerId].engines) do
                if player_data[playerId].engines[i].block.Exists() then
                local block = player_data[playerId].engines[i].block
                local power = 0
                for j,_ in pairs(engine_cc_list) do
                    if block.GetSecondaryColor().ToString()==engine_cc_list[j].color then
                        power = engine_cc_list[j].cc*22.22
                        player_data[playerId].selected_engine_cc = engine_cc_list[j].cc
                        if player_data[playerId].wheels[1].amount==2 or player_data[playerId].wheels[2].amount==2 then
                            power = power + motorcycle_buff
                        end
                        break
                    end
                end
                if block.GetEnginePower() ~= power then
                    if profiling>0 then
                        tm.os.Log(tm.players.GetPlayerName(playerId).. " (".. playerId.. ")'s engine power is out of sync, updating...")
                    end
                    tm.audio.PlayAudioAtGameobject("Build_attach_Weapon", tm.players.GetPlayerGameObject(playerId))
                    block.SetEnginePower(power)
                end
                end
            end
        end
        if live_block_count ~= player_data[playerId].block_count then
            if profiling>0 then
                tm.os.Log("Build was updated for ".. tm.players.GetPlayerName(playerId).. " (".. playerId.. "), updating data...")
                --tm.os.Log("Build has ".. live_block_count.. " blocks right now")
                --tm.os.Log("Build had ".. player_data[playerId].block_count.. " blocks")
            end
            player_data[playerId].block_count = live_block_count
            tm.audio.PlayAudioAtGameobject("Build_attach_Flag", tm.players.GetPlayerGameObject(playerId))
            player_data[playerId].total_buoyancy = 0
            player_data[playerId].total_weight = 0
            player_data[playerId].has_banned_blocks = false
            player_data[playerId].banned_blocks = {}
            player_data[playerId].total_engines = 0
            player_data[playerId].wheels = {
                {type="3x3x1",amount=0},
                {type="3x3x2",amount=0}
            }
            player_data[playerId].engines = {}
            for _,structure in ipairs(structures) do
                local blocks = structure.GetBlocks()
                local banned_blocks = {}
                for index,block in pairs(blocks) do
                    local value = block_types[string.sub(block.GetName(), 5, -10)]

                    -- multiply mass by 5 to convert to kg
                    player_data[playerId].total_buoyancy = player_data[playerId].total_buoyancy + block.GetBuoyancy()*5
                    player_data[playerId].total_weight = player_data[playerId].total_weight + block.GetMass()*5

                    if value == "3x3x1" then
                        block.SetBuoyancy(9) -- multiply buoyancy by 5 to convert to kg
                        player_data[playerId].wheels[1].amount = player_data[playerId].wheels[1].amount + 1 -- Count wheels for bike buff eligibility check
                    end
                    if value == "3x3x2" then
                        block.SetBuoyancy(9)
                        player_data[playerId].wheels[2].amount = player_data[playerId].wheels[2].amount + 1 -- Count wheels for bike buff eligibility check
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

                    if value == "engine" then
                        player_data[playerId].total_engines = player_data[playerId].total_engines + 1
                        player_data[playerId].engines[#player_data[playerId].engines+1] = {block=nil}
                        player_data[playerId].engines[#player_data[playerId].engines].block = block
                    end

                    if value == "banned" then
                        player_data[playerId].has_banned_blocks = true
                        table.insert(player_data[playerId].banned_blocks, string.sub(block.GetName(), 5, -10))
                    end
                end
                -- Log the current engine's secondary color. Un comment this when adding new cc colors
                --if value == "engine" then tm.os.Log(block.GetSecondaryColor().ToString()) end
                for i,_ in ipairs(player_data[playerId].engines) do
                    local block = player_data[playerId].engines[i].block
                    block.SetEnginePower(0) -- Set to zero so if there's an invalid kart setup it remains as zero
                    if #player_data[playerId].banned_blocks==0 then
                        if player_data[playerId].total_engines==0 then
                            for i,_ in pairs(engine_cc_list) do
                                if block.GetSecondaryColor().ToString()==engine_cc_list[i].color then
                                    block.SetEnginePower(engine_cc_list[i].cc*22.22)
                                    player_data[playerId].selected_engine_cc = engine_cc_list[i].cc
                                    if player_data[playerId].wheels[1].amount==2 or player_data[playerId].wheels[2].amount==2 then
                                        block.SetEnginePower(block.GetEnginePower()+motorcycle_buff)
                                    end
                                end
                            end
                        else
                            for _,block in ipairs(blocks) do
                                local value = block_types[string.sub(block.GetName(), 5, -10)]
                                if value == "engine" then
                                    block.SetEnginePower(0)
                                end
                            end
                        end
                    end
                end
                for _,_ in pairs(player_data[playerId].banned_blocks) do
                    for _,block in ipairs(blocks) do
                        local value = block_types[string.sub(block.GetName(), 5, -10)]
                        if value == "engine" then
                            block.SetEnginePower(0)
                        end
                    end
                end
            end
        end
        if profiling==1 then
            profiling_structure_checking_time = profiling_structure_checking_time + tm.os.GetRealtimeSinceStartup()-profiling_structure_checking_start_time
        end
    end
end

function UpdateUI(playerId)
    local profiling_ui_start_time = tm.os.GetRealtimeSinceStartup()
    if not tm.players.GetPlayerIsInBuildMode(playerId) then
        ClearUIWindow(playerId)
        player_data[playerId].ui_visible = false
        return
    end

    tm.playerUI.RemoveUI(playerId, "error.banned_blocks")
    for i = 0,player_data[playerId].banned_blocks_ui_size do
        tm.playerUI.RemoveUI(playerId, "error.banned_blocks-".. i)
    end
    tm.playerUI.RemoveUI(playerId, "error.too_many_engines")
    if player_data[playerId].has_banned_blocks==true then
        tm.playerUI.AddUILabel(playerId, "error.banned_blocks", "<b><color=#E22>Your kart has banned blocks!</color></b>")
        player_data[playerId].banned_blocks_ui_size = 0
        for i,_ in ipairs(player_data[playerId].banned_blocks) do
            tm.playerUI.AddUILabel(playerId, "error.banned_blocks-".. i, "<i>".. player_data[playerId].banned_blocks[i].. "</i>")
            player_data[playerId].banned_blocks_ui_size = player_data[playerId].banned_blocks_ui_size + 1
        end
        tm.audio.PlayAudioAtGameobject("Build_rotate_weapon", tm.players.GetPlayerGameObject(playerId))
        return
    end
    if player_data[playerId].total_engines>1 then
        tm.playerUI.AddUILabel(playerId, "error.too_many_engines", "<b><color=#E22>You can only have one engine!</color></b>")
        tm.audio.PlayAudioAtGameobject("Build_rotate_weapon", tm.players.GetPlayerGameObject(playerId))
        return
    end


    if player_data[playerId].ui_visible == true then
        if player_data[playerId].has_banned_blocks==false then
            if player_data[playerId].total_engines<2 then
                tm.playerUI.SetUIValue(playerId, "total_buoyancy", string.format("%.1f", player_data[playerId].total_buoyancy).. "kg total vehicle buoyancy")
                tm.playerUI.SetUIValue(playerId, "total_weight", string.format("%.1f", player_data[playerId].total_weight).. "kg total vehicle weight")

                local block = tm.players.GetPlayerSelectBlockInBuild(playerId)
                if block~=nil then
                    -- Get hex code of the selected block's secondary color
                    local color = block.GetSecondaryColor()
                    local rgb = (color.R()*255 * 0x10000) + (color.G()*255 * 0x100) + color.B()*255
                    local shex = string.format("%06x", rgb)
                    
                    if player_data[playerId].selected_block_ui_visible==true then
                        tm.playerUI.SetUIValue(playerId, "selected_block.name", string.sub(block.GetName(), 5, -10))
                        tm.playerUI.SetUIValue(playerId, "selected_block.mass", "Weight: ".. string.format("%0.1f", block.GetMass()*5) .. "kg")
                        tm.playerUI.SetUIValue(playerId, "selected_block.buoyancy", "Buoyancy: ".. string.format("%0.1f", block.GetBuoyancy()*5) .. "kg")
                        tm.playerUI.SetUIValue(playerId, "selected_block.secondary_color", "Secondary color: <color=#".. shex.. ">██</color> #".. shex)
                        if block.IsEngineBlock() then
                            local engine_power = block.GetEnginePower()
                            if engine_power ~= 0 then
                                tm.playerUI.SetUIValue(playerId, "selected_block.engine_power", player_data[playerId].selected_engine_cc .. "cc | ".. engine_power.. " power")
                            else
                                tm.playerUI.SetUIValue(playerId, "selected_block.engine_power", "<color=#FAA>Invalid secondary color!</color>") 
                            end
                        else
                            tm.playerUI.SetUIValue(playerId, "selected_block.engine_power", "<color=#666>N/A</color>") 
                        end
                    else
                        tm.playerUI.AddUILabel(playerId, "newline", "")
                        tm.playerUI.AddUILabel(playerId, "selected_block.name", string.sub(tm.players.GetPlayerSelectBlockInBuild(playerId).GetName(), 5, -10))
                        tm.playerUI.AddUILabel(playerId, "selected_block.mass", "Weight: ".. string.format("%0.1f", tm.players.GetPlayerSelectBlockInBuild(playerId).GetMass()*5) .. "kg")
                        tm.playerUI.AddUILabel(playerId, "selected_block.buoyancy", "Buoyancy: ".. string.format("%0.1f", tm.players.GetPlayerSelectBlockInBuild(playerId).GetBuoyancy()*5) .. "kg")
                        tm.playerUI.AddUILabel(playerId, "selected_block.secondary_color", "Secondary color: <color=#".. shex.. ">██</color> #".. shex)
                        if block.IsEngineBlock() then
                            local engine_power = block.GetEnginePower()
                            if engine_power ~= 0 then
                                tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", player_data[playerId].selected_engine_cc .. "cc | ".. engine_power.. " power")
                            else
                                tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", "<color=#FAA>Invalid secondary color!</color>") 
                            end
                        else
                            tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", "<color=#666>N/A</color>") 
                        end
                        player_data[playerId].selected_block_ui_visible = true
                    end
                else
                    player_data[playerId].selected_block_ui_visible = false
                    tm.playerUI.RemoveUI(playerId, "newline")
                    tm.playerUI.RemoveUI(playerId, "selected_block.name")
                    tm.playerUI.RemoveUI(playerId, "selected_block.mass")
                    tm.playerUI.RemoveUI(playerId, "selected_block.buoyancy")
                    tm.playerUI.RemoveUI(playerId, "selected_block.secondary_color")
                    tm.playerUI.RemoveUI(playerId, "selected_block.engine_power")
                end
            end
        end
    else
        player_data[playerId].ui_visible = true
        tm.playerUI.AddUILabel(playerId, "total_buoyancy", string.format("%.1f", player_data[playerId].total_buoyancy).. "kg total vehicle buoyancy")
        tm.playerUI.AddUILabel(playerId, "total_weight", string.format("%.1f", player_data[playerId].total_weight).. "kg total vehicle weight") -- Inaccurate vehicle weight isn't a bug; steering hinge has a misleading in-game weight value   
    end
    if profiling==1 then
        local endtime = tm.os.GetRealtimeSinceStartup()
        profiling_ui_time = profiling_ui_time + endtime-profiling_ui_start_time
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
    if profiling_local_gravity_time~=0 then
        tm.os.Log(" ".. string.format("%0.4s", profiling_local_gravity_time*1000) .. " ms for local gravity")
    else
        tm.os.Log("<0.01 ms for local gravity")
    end
    local overhead = (profiling_mod_end_time-profiling_mod_start_time)-(profiling_structure_checking_time+profiling_ui_time+profiling_local_gravity_time)
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