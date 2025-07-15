tm.os.Log("KartMakers by HormaV5 (Project lead), RainlessSky (Programmer), Antimatterdev (Fake programmer)")
tm.os.Log("")

tm.physics.AddTexture("KartOutline.png", "icon")
tm.physics.AddTexture("engine.png", "km_engine")
tm.physics.AddTexture("thrust.png", "km_thrust")

tm.os.SetModTargetDeltaTime(1/60)

-- Enable performance logging. 0 = off, 1 = all, 2 = limited
local profiling = 2

local profiling_structure_checking_time = 0
local profiling_ui_time = 0
local profiling_local_gravity_time = 0
local profiling_mod_start_time = 0

-- Config
local local_gravity = false -- Toggle Local Gravity on/off
local magnet_fling = false -- Toggle Magnet Fling on/off
local magnet_fling_duration = 1.5 -- How long the magnet fling lasts for (seconds) | Default: 1.5
local magnet_fling_strength = 2 -- Strength for magnet fling | Default: 2
local global_engine_power_multiplier = 1 -- Multiplier for engine CC/Power
local max_thruster_power = 300 -- Max thrust per kart

player_data = {}
function OnPlayerJoined(player)
    player_data[player.playerId] = {
        total_buoyancy = 0,
        total_weight = 0,
        total_thrust = 0,
        block_count = 0,
        has_banned_blocks = false,
        banned_blocks = {},
        total_engines = 0,
        wheels = 0,
        selected_engine_cc = 0,
        engines = {},
        HasGroundContact = true,
        magnet_duration = 0,

        ui_visible = false,
        banned_blocks_ui_size = 0,
        banned_blocks_ui_visible = false,
        too_many_engines_ui_visible = false,
        wheels_error_ui_visible = false,
        thrust_error_ui_visible = false,

        build_mode_subtle_message_data = {
            visible=false,
            {id="engine_cc_message", message=nil},
            {id="thruster_power_message", message=nil}
        }
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

    ModularTubeSystem_TubeDoubleElbow = "tubes_3", -- 3 nubs
    ModularTubeSystem_Skewed1x1x2 = "tubes_2", -- 2 nubs
    ModularTubeSystem_Tube1x1x8 = "tubes_2", -- 2 nubs
    ModularTubeSystem_Skewed2x1x2 = "tubes_2", -- 2 nubs
    ModularTubeSystem_TubeTeeCross = "tubes_5", -- 5 nubs
    ModularTubeSystem_DoubleCross = "tubes_6", -- 6 nubs
    ModularTubeSystem_Tube3x1 = "tubes_2", -- 2 nubs
    ModularTubeSystem_TubeDoubleTee = "tubes_4", -- 4 nubs
    ModularTubeSystem_Tube1x4 = "tubes_2", -- 2 nubs
    ModularTubeSystem_TubeTee = "tubes_3", -- 3 nubs
    ModularTubeSystem_Tube1x1 = "tubes_2", -- 2 nubs
    ModularTubeSystem_TubeElbow = "tubes_2", -- 2 nubs
    ModularTubeSystem_TubeCross = "tubes_2", -- 4 nubs
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

    -- gyro changes
    GyroStabilizer = "gyro_stabilizer",
    AngleSensorBlock = "angle_sensor",
    InertialRedirector = "quantum_rudder",
    HingeLarge = "large_hinge",

    -- thruster tiers
    JetEngineMini =  "t1_thruster", -- Thruster
    SpaceThruster =  "t2_thruster", -- Space Thruster
    JetEngineNinja = "t3_thruster", -- Dragon Jet

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
    JetTiny = "banned",
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

local engine_power_list = { -- this holds the power value and custom weight for each engine type
    {name="EngineBasic",    cc=150*global_engine_power_multiplier, weight=3}, -- Bulldawg Engine
    {name="EngineNinja",    cc=100*global_engine_power_multiplier, weight=5}, -- Dragon Engine
    {name="EngineOlSchool", cc=125*global_engine_power_multiplier, weight=7}, -- Raw Engine
}

--tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Subtle message icon test", 10, "icon")

if local_gravity==true then tm.physics.SetGravityMultiplier(0) tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Playing with Local Gravity", 3, "icon") end
if magnet_fling ==true then tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Playing with Magnet Fling", 3, "icon") end

function update()
    if profiling==1 then profiling_mod_start_time = tm.os.GetRealtimeSinceStartup() profiling_structure_checking_time = 0 profiling_ui_time = 0 profiling_local_gravity_time = 0 end

    local players = tm.players.CurrentPlayers()
    for _, player in ipairs(players) do
        local playerId = player.playerId
        CheckStructures(playerId)
        UpdateUI(playerId)

        -- Per-player anti-gravity toggle
        if local_gravity==true or magnet_fling==true then ApplyLocalGravity(playerId) end
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

    local hit = tm.physics.RaycastData(origin, worldDown, rayLength, true)

    local deltatime = (1/tm.os.GetModTargetDeltaTime())*tm.os.GetModDeltaTime()
    local gravityStrength = (weight * 0.047) * deltatime
    --tm.os.Log(deltatime)

    local magnet_fling_duration = magnet_fling_duration * 60

    if hit and hit.DidHit() then
        local hitNormal = hit.GetHitNormal()

        --tm.os.Log("Ground normal: " .. tostring(hitNormal))
        -- 0.33
        if local_gravity==true then structure.AddForce(worldDown.x * gravityStrength, worldDown.y * gravityStrength, worldDown.z * gravityStrength) end
        if magnet_fling==false then return end
        player_data[playerId].HasGroundContact = true
        if player_data[playerId].magnet_duration > 0 then
            player_data[playerId].magnet_duration = 0
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Stop", tm.players.GetPlayerGameObject(playerId))
        end
    else
        if player_data[playerId].HasGroundContact==true then
            if magnet_fling==true then
            player_data[playerId].magnet_duration = magnet_fling_duration -- Duration in mod updates (60 = 1 second) magnet fling lasts for
            if profiling>0 then tm.os.Log(tm.players.GetPlayerName(playerId).. " got magnet fling") end
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Start", tm.players.GetPlayerGameObject(playerId))
            end
        else
            structure.AddForce(0, -gravityStrength, 0)
        end
        player_data[playerId].HasGroundContact = false
    end

    if player_data[playerId].magnet_duration > 0 then
        local magnet_remaining = player_data[playerId].magnet_duration / magnet_fling_duration
        local a = magnet_remaining
        local a2 = a^2

        -- Exponential in/out easing (I think regular ease in/out is better)
        --local easing = 0.5 -- Fallback value
        --if a <= 0.5 then
            --easing = 0.5 * 2^(20*(a - 0.5))
        --else
            --easing = 0.5 * (-(2^-(20*(a - 0.5))) + 2)
        --end
        local easing = a2/(2*(a2-a)+1) -- Ease in/out, probably
        local multiplier = gravityStrength * easing*magnet_fling_strength
        --tm.os.Log(string.format("%0.2f", easing)*100 .. "% provides ".. string.format("%0.2f", multiplier).. " multiplier")

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
        if player_data[playerId].has_banned_blocks==false and #player_data[playerId].engines<2 and player_data[playerId].total_thrust<=300 then
            for i,_ in ipairs(player_data[playerId].engines) do
                --tm.os.Log("Checking engine #".. i)
                if player_data[playerId].engines[i].block.Exists() then
                    local block = player_data[playerId].engines[i].block
                    local power = 0
                    --tm.os.Log("  Engine exists, calculating power...")
                    if player_data[playerId].wheels>2 and player_data[playerId].wheels<=6 then
                        --tm.os.Log("    Wheel check passed")
                        for j,_ in ipairs(engine_power_list) do
                            --tm.os.Log("      Checking engine type #".. j)
                            if string.sub(block.GetName(), 5, -10) == engine_power_list[j].name then
                                power = engine_power_list[j].cc*22.22
                                player_data[playerId].selected_engine_cc = engine_power_list[j].cc
                                --tm.os.Log(        "Engine is type #".. j.. " | Calculated power is now ".. power)
                                break
                            end
                        end
                    else
                        --tm.os.Log("    Wheel check failed")
                    end
                    if block.GetEnginePower() ~= power then
                        tm.os.Log("  Engine power was updated. Current power: ".. block.GetEnginePower().. " | Calculated power: ".. power)
                        if profiling>0 then
                            tm.os.Log(tm.players.GetPlayerName(playerId).. " (".. playerId.. ")'s engine power is out of sync, updating...")
                        end
                        tm.audio.PlayAudioAtGameobject("Build_attach_Weapon", tm.players.GetPlayerGameObject(playerId))
                        block.SetEnginePower(power)
                        player_data[playerId].engines[#player_data[playerId].engines].power = block.GetEnginePower()
                    else
                        --tm.os.Log("  Engine power is identical. Current power: ".. block.GetEnginePower().. " | Calculated power: ".. power)
                    end
                else
                    tm.os.Log("  Engine does not exist, forcing cache refresh...")
                    player_data[playerId].block_count = -1
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
            player_data[playerId].total_thrust = 0
            player_data[playerId].has_banned_blocks = false
            player_data[playerId].banned_blocks = {}
            player_data[playerId].total_engines = 0
            player_data[playerId].selected_engine_cc = 0
            player_data[playerId].wheels = 0
            player_data[playerId].engines = {}
            for _,structure in ipairs(structures) do
                local blocks = structure.GetBlocks()
                for i,block in pairs(blocks) do
                    local value = block_types[string.sub(block.GetName(), 5, -10)]

                    if value == "2x2x1" then -- gokart wheel
                        block.SetBuoyancy(4) -- multiply buoyancy by 5 to convert to kg
                        player_data[playerId].wheels = player_data[playerId].wheels + 1
                    end
                    if value == "3x3x1" then
                        block.SetBuoyancy(9)
                        player_data[playerId].wheels = player_data[playerId].wheels + 1
                    end
                    if value == "3x3x2" then
                        block.SetBuoyancy(9)
                        player_data[playerId].wheels = player_data[playerId].wheels + 1
                    end
                    if value == "5x5x2" then -- truck wheel
                        block.SetBuoyancy(12)
                        player_data[playerId].wheels = player_data[playerId].wheels + 1
                    end
                    if value == "7x7x4" then -- monster truck wheel
                        block.SetBuoyancy(20) -- multiply buoyancy by 5 to convert to kg
                        player_data[playerId].wheels = player_data[playerId].wheels + 1
                    end
                    if value == "4x1x1" then -- skis and pistons
                        block.SetBuoyancy(32)
                        block.SetDragAll(0.1, 0.1, 0.1, 0.1, 0.1, 0.1) -- automatically anti-drag pistons and skis
                    end
                    if value == "seat" then
                        block.SetDragAll(0.1, 0.1, 0.1, 0.1, 0.1, 0.1)
                    end
                    if value == "decoration" then -- lights, steering hinge, camera block
                        block.SetDragAll(0.1, 0.1, 0.1, 0.1, 0.1, 0.1)
                    end
                    if value == "tubes_2" then -- 0.2 per nub
                        block.SetDragAll(0.4, 0.4, 0.4, 0.4, 0.4, 0.4)
                    end
                    if value == "tubes_3" then
                        block.SetDragAll(0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
                    end
                    if value == "tubes_4" then
                        block.SetDragAll(0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
                    end
                    if value == "tubes_5" then
                        block.SetDragAll(1, 1, 1, 1, 1, 1)
                    end
                    if value == "tubes_6" then
                        block.SetDragAll(1, 1, 1, 1, 1, 1)
                    end

                    if value == "engine" then
                        player_data[playerId].total_engines = player_data[playerId].total_engines + 1
                        player_data[playerId].engines[#player_data[playerId].engines+1] = {block=nil,power=nil}
                        player_data[playerId].engines[#player_data[playerId].engines].block = block
                        player_data[playerId].engines[#player_data[playerId].engines].power = block.GetEnginePower()
                    end

                    if value == "gyro_stabilizer" then
                        block.SetMass(2)
                    end
                    if value == "angle_sensor" then
                        block.SetMass(0.2)
                    end
                    if value == "quantum_rudder" then
                        block.SetMass(1.6)
                    end
                    if value == "large_hinge" then
                        block.SetMass(0.4)
                    end

                    if value == "t1_thruster" then
                        block.SetMass(1.5)
                        block.SetJetPower(125)
                    end
                    if value == "t2_thruster" then
                        block.SetMass(2.5)
                        block.SetJetPower(200)
                    end
                    if value == "t3_thruster" then
                        block.SetMass(4.5)
                    end

                    if block.IsPlayerSeatBlock() then
                        block.SetDragAll(0.15, 0.5, 0.5, 0.5, 0.5, 0.5)
                    end

                    if value == "banned" then
                        player_data[playerId].has_banned_blocks = true
                        table.insert(player_data[playerId].banned_blocks, string.sub(block.GetName(), 5, -10))
                    end

                    if block.IsJetBlock() then
                        player_data[playerId].total_thrust = player_data[playerId].total_thrust + block.GetJetPower()
                    end

                    -- multiply mass by 5 to convert to kg
                    player_data[playerId].total_buoyancy = player_data[playerId].total_buoyancy + block.GetBuoyancy()*5
                    player_data[playerId].total_weight = player_data[playerId].total_weight + block.GetMass()*5
                end
                for i,_ in ipairs(player_data[playerId].engines) do
                    local block = player_data[playerId].engines[i].block
                    block.SetEnginePower(0) -- Set to zero so if there's an invalid kart setup it remains as zero
                    if #player_data[playerId].banned_blocks==0 then
                        for j,_ in ipairs(engine_power_list) do
                            if string.sub(block.GetName(), 5, -10) == engine_power_list[j].name then
                                block.SetEnginePower(engine_power_list[j].cc*22.22)
                                block.SetMass(engine_power_list[j].weight)
                                player_data[playerId].engines[#player_data[playerId].engines].power = block.GetEnginePower()
                                player_data[playerId].selected_engine_cc = engine_power_list[j].cc
                                --tm.os.Log("Found engine match! Engine power is now ".. block.GetEnginePower())
                                break
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
                if player_data[playerId].has_banned_blocks == true or player_data[playerId].wheels<3 or player_data[playerId].wheels>6 or player_data[playerId].total_thrust>max_thruster_power then
                    for _,block in ipairs(blocks) do
                        local value = block_types[string.sub(block.GetName(), 5, -10)]
                        if value == "engine" then
                            block.SetEnginePower(0)
                        end
                    end
                end
            end
            if player_data[playerId].build_mode_subtle_message_data.visible==true then
                UpdateBuildModeSubtleMessages(playerId)
            end
        end
        if profiling==1 then
            profiling_structure_checking_time = profiling_structure_checking_time + tm.os.GetRealtimeSinceStartup()-profiling_structure_checking_start_time
        end
    end
end

function AddBuildModeSubtleMessages(playerId)
    player_data[playerId].build_mode_subtle_message_data[1].message = tm.playerUI.AddSubtleMessageForPlayer(playerId, "", "Your kart is ".. tostring(player_data[playerId].selected_engine_cc).. "cc", 32767, "km_engine")
    player_data[playerId].build_mode_subtle_message_data[2].message = tm.playerUI.AddSubtleMessageForPlayer(playerId, "", "Your kart has ".. tostring(player_data[playerId].total_thrust).. "/".. max_thruster_power.. " thrust", 32767, "km_thrust")
    player_data[playerId].build_mode_subtle_message_data.visible = true
end

function UpdateBuildModeSubtleMessages(playerId)
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, player_data[playerId].build_mode_subtle_message_data[1].message, "Your kart is ".. tostring(player_data[playerId].selected_engine_cc).. "cc")
     tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, player_data[playerId].build_mode_subtle_message_data[2].message, "Your kart has ".. tostring(player_data[playerId].total_thrust).. "/".. max_thruster_power.. " power")
end


function ClearBuildModeSubtleMessages(playerId)
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, player_data[playerId].build_mode_subtle_message_data[1].message)
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, player_data[playerId].build_mode_subtle_message_data[2].message)
    player_data[playerId].build_mode_subtle_message_data[1].message = nil
    player_data[playerId].build_mode_subtle_message_data[2].message = nil
    player_data[playerId].build_mode_subtle_message_data.visible = false
end

function ClearUIWindow(playerId)
    if player_data[playerId].banned_blocks_ui_visible == true then
        for i = 0,player_data[playerId].banned_blocks_ui_size do
            tm.playerUI.RemoveUI(playerId, "error.banned_blocks-".. i)
        end
        tm.playerUI.RemoveUI(playerId, "error.banned_blocks")
        player_data[playerId].banned_blocks_ui_visible = false
    end
    if player_data[playerId].too_many_engines_ui_visible == true then
        tm.playerUI.RemoveUI(playerId, "error.too_many_engines")
        player_data[playerId].too_many_engines_ui_visible = false
    end
    if player_data[playerId].wheels_error_ui_visible == true then
        tm.playerUI.RemoveUI(playerId, "error.wheels_error")
        player_data[playerId].wheels_error_ui_visible = false
    end
    if player_data[playerId].thrust_error_ui_visible == true then
        tm.playerUI.RemoveUI(playerId, "error.thrust_error")
        player_data[playerId].thrust_error_ui_visible = false
    end
    if player_data[playerId].selected_block_ui_visible == true then
        tm.playerUI.RemoveUI(playerId, "selected_block.engine_power")
        tm.playerUI.RemoveUI(playerId, "selected_block.buoyancy")
        tm.playerUI.RemoveUI(playerId, "selected_block.mass")
        tm.playerUI.RemoveUI(playerId, "selected_block.secondary_color")
        tm.playerUI.RemoveUI(playerId, "selected_block.name")
        tm.playerUI.RemoveUI(playerId, "newline")
        player_data[playerId].selected_block_ui_visible = false
    end
    if player_data[playerId].ui_visible == true then
        tm.playerUI.RemoveUI(playerId, "total_weight")
        tm.playerUI.RemoveUI(playerId, "total_buoyancy")
        player_data[playerId].ui_visible = false
    end
end

function UpdateUI(playerId)
    local profiling_ui_start_time = tm.os.GetRealtimeSinceStartup()

    -- If they're not in build mode, remove the ui and end the function
    if not tm.players.GetPlayerIsInBuildMode(playerId) then
        -- Don't do what i just did for the conditions in the following if check. It's really dumb and the line is so long
        if player_data[playerId].ui_visible==true or player_data[playerId].selected_block_ui_visible == true or player_data[playerId].too_many_engines_ui_visible == true or player_data[playerId].banned_blocks_ui_visible == true or player_data[playerId].wheels_error_ui_visible == true or player_data[playerId].thrust_error_ui_visible == true then
            ClearUIWindow(playerId)
            ClearBuildModeSubtleMessages(playerId)
        end
        return
    end

    if player_data[playerId].build_mode_subtle_message_data.visible==false then
        AddBuildModeSubtleMessages(playerId)
    end

    -- If they're in build mode, do all of the below

    -- Banned blocks error ui
    if player_data[playerId].banned_blocks_ui_visible==true then -- Remove banned blocks ui if it actually exists
        player_data[playerId].banned_blocks_ui_visible = false
        tm.playerUI.RemoveUI(playerId, "error.banned_blocks")
        for i = 0,player_data[playerId].banned_blocks_ui_size do
            tm.playerUI.RemoveUI(playerId, "error.banned_blocks-".. i)
        end
    end
    if player_data[playerId].has_banned_blocks==true then -- If they have banned blocks, generate ui
        tm.playerUI.AddUILabel(playerId, "error.banned_blocks", "<b><color=#E22>Your kart has banned blocks!</color></b>")
        player_data[playerId].banned_blocks_ui_size = 0
        for i,_ in ipairs(player_data[playerId].banned_blocks) do
            tm.playerUI.AddUILabel(playerId, "error.banned_blocks-".. i, "<i>".. player_data[playerId].banned_blocks[i].. "</i>")
            player_data[playerId].banned_blocks_ui_size = player_data[playerId].banned_blocks_ui_size + 1
        end
        player_data[playerId].banned_blocks_ui_visible = true
        tm.audio.PlayAudioAtGameobject("UI_General_Toggle_Click", tm.players.GetPlayerGameObject(playerId))
        return
    end

    -- Too many engines error ui
    if player_data[playerId].too_many_engines_ui_visible==true then -- Check if too many engines ui actually exists
        tm.playerUI.RemoveUI(playerId, "error.too_many_engines")
        player_data[playerId].too_many_engines_ui_visible = false
    end
    if player_data[playerId].total_engines>1 then -- If the player has more than one engine, display the "too many engines" error
        tm.playerUI.AddUILabel(playerId, "error.too_many_engines", "<b><color=#E22>You can only have one engine!</color></b>")
        player_data[playerId].too_many_engines_ui_visible = true
        tm.audio.PlayAudioAtGameobject("UI_General_Toggle_Click", tm.players.GetPlayerGameObject(playerId))
        return
    end

    -- Wheels error error ui
    if player_data[playerId].wheels_error_ui_visible==true then -- Check if too many engines ui actually exists
        tm.playerUI.RemoveUI(playerId, "error.wheels_error")
        player_data[playerId].wheels_error_ui_visible = false
    end
    if player_data[playerId].wheels>0 then
        if player_data[playerId].wheels<3 or player_data[playerId].wheels>6 then -- If the player doesn't have 3-6 wheels, display the "wheels error" error
            tm.playerUI.AddUILabel(playerId, "error.wheels_error", "<b><color=#E22>You must have 3-6 wheels!</color></b>")
            player_data[playerId].wheels_error_ui_visible = true
            -- UI_General_Toggle_Click
            tm.audio.PlayAudioAtGameobject("UI_General_Toggle_Click", tm.players.GetPlayerGameObject(playerId))
            return
        end
    end

    -- Too much thrust error ui
    if player_data[playerId].thrust_error_ui_visible==true then -- Check if too many engines ui actually exists
        tm.playerUI.RemoveUI(playerId, "error.thrust_error")
        player_data[playerId].thrust_error_ui_visible = false
    end
    if player_data[playerId].total_thrust>max_thruster_power then
        tm.playerUI.AddUILabel(playerId, "error.thrust_error", "<b><color=#E22>You cannot have >".. max_thruster_power.. " thrust!</color></b>")
        player_data[playerId].thrust_error_ui_visible = true
        -- UI_General_Toggle_Click
        tm.audio.PlayAudioAtGameobject("UI_General_Toggle_Click", tm.players.GetPlayerGameObject(playerId))
        return
    end

    -- Build mode ui
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
                            tm.playerUI.SetUIValue(playerId, "selected_block.engine_power", player_data[playerId].selected_engine_cc.. "cc | ".. engine_power.. " power")
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
                            tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", player_data[playerId].selected_engine_cc.. "cc | ".. engine_power.. " power")
                        else
                            tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", "<color=#666>N/A</color>") 
                        end
                        player_data[playerId].selected_block_ui_visible = true
                    end
                else
                    if player_data[playerId].selected_block_ui_visible==true then
                        tm.playerUI.RemoveUI(playerId, "newline")
                        tm.playerUI.RemoveUI(playerId, "selected_block.name")
                        tm.playerUI.RemoveUI(playerId, "selected_block.mass")
                        tm.playerUI.RemoveUI(playerId, "selected_block.buoyancy")
                        tm.playerUI.RemoveUI(playerId, "selected_block.secondary_color")
                        tm.playerUI.RemoveUI(playerId, "selected_block.engine_power")
                    end
                    player_data[playerId].selected_block_ui_visible = false
                end
            end
        end
    else
        tm.playerUI.AddUILabel(playerId, "total_buoyancy", string.format("%.1f", player_data[playerId].total_buoyancy).. "kg total vehicle buoyancy")
        tm.playerUI.AddUILabel(playerId, "total_weight", string.format("%.1f", player_data[playerId].total_weight).. "kg total vehicle weight") -- Inaccurate vehicle weight isn't a bug; steering hinge has a misleading in-game weight value   
        player_data[playerId].ui_visible = true
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