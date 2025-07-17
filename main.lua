tm.os.Log("KartMakers by HormaV5 (Project lead), RainlessSky (Programmer), Antimatterdev (Fake programmer)")

tm.physics.AddTexture("KartOutline.png", "icon")
tm.physics.AddTexture("engine.png", "km_engine")
tm.physics.AddTexture("thrust.png", "km_thrust")

tm.os.SetModTargetDeltaTime(1/60)

-- Enable performance logging. 0 = off, 1 = all, 2 = limited
Profiling = 0

Profiling_structure_checking_time = 0
Profiling_ui_time = 0
Profiling_local_gravity_time = 0
Profiling_mod_start_time = 0

-- Config
Local_Gravity = false -- Toggle Local Gravity on/off
Magnet_Fling = false -- Toggle Magnet Fling on/off
Magnet_Fling_Duration = 1.5 -- How long the magnet fling lasts for (seconds) | Default: 1.5
Magnet_Fling_Strength = 2 -- Strength for magnet fling | Default: 2
Global_Engine_Power_Multiplier = 1 -- Multiplier for engine CC/Power
Max_Thruster_Power = 300 -- Max thrust per kart
Minimum_Wheels = 2

Player_Data = {}
function OnPlayerJoined(player)
    Player_Data[player.playerId] = {
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

Block_Types = {
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

    -- anti-drag nerfs
    BracketBlock = "l_bracket",

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

Engine_Power_List = { -- this holds the power value and custom weight for each engine type
    {name="EngineBasic",    cc=150*Global_Engine_Power_Multiplier, weight=3}, -- Bulldawg Engine
    {name="EngineNinja",    cc=100*Global_Engine_Power_Multiplier, weight=5}, -- Dragon Engine
    {name="EngineOlSchool", cc=125*Global_Engine_Power_Multiplier, weight=7}, -- Raw Engine
}

--tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Subtle message icon test", 10, "icon")

if Local_Gravity==true then tm.physics.SetGravityMultiplier(0) tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Playing with Local Gravity", 3, "icon") end
if Magnet_Fling ==true then tm.playerUI.AddSubtleMessageForAllPlayers("KartMakers", "Playing with Magnet Fling", 3, "icon") end

function update()
    if Profiling==1 then Profiling_mod_start_time = tm.os.GetRealtimeSinceStartup() Profiling_structure_checking_time = 0 Profiling_ui_time = 0 Profiling_local_gravity_time = 0 end

    local players = tm.players.CurrentPlayers()
    for _, player in ipairs(players) do
        local playerId = player.playerId
        KartMakers.CheckStructures.Execute(playerId)
        KartMakers.UpdateUI.Execute(playerId)

        if Local_Gravity==true or Magnet_Fling==true then KartMakers.LocalGravity.Execute(playerId) end
    end

    if Profiling==1 then PrintProfilingData(tm.os.GetRealtimeSinceStartup()) end
end

function PrintProfilingData(Profiling_mod_end_time)
    if Profiling_structure_checking_time~=0 then
        tm.os.Log(" ".. string.format("%0.4s", Profiling_structure_checking_time*1000) .. " ms for structure checking")
    else
        tm.os.Log("<0.01 ms for structure checking")
    end
    if Profiling_ui_time~=0 then
        tm.os.Log(" ".. string.format("%0.4s", Profiling_ui_time*1000) .. " ms for ui")
    else
        tm.os.Log("<0.01 ms for ui")
    end
    if Profiling_local_gravity_time~=0 then
        tm.os.Log(" ".. string.format("%0.4s", Profiling_local_gravity_time*1000) .. " ms for local gravity")
    else
        tm.os.Log("<0.01 ms for local gravity")
    end
    local overhead = (Profiling_mod_end_time-Profiling_mod_start_time)-(Profiling_structure_checking_time+Profiling_ui_time+Profiling_local_gravity_time)
    if overhead~=0 then
        tm.os.Log(" ".. string.format("%0.4s", overhead*1000) .. " ms overhead")
    else
        tm.os.Log("<0.01 ms for overhead")
    end
    if (Profiling_mod_end_time-Profiling_mod_start_time)*1000~=0 then
        tm.os.Log(" ".. string.format("%0.4s", (Profiling_mod_end_time-Profiling_mod_start_time)*1000) .. " ms for update()")
    else
        tm.os.Log("<0.01 ms for update()")
    end
    tm.os.Log("")
end

KartMakers = {
    -- Ideally use KartMakers.Playground for temporary functions
    Playground = tm.os.DoFile("KM_Playground"),

    CheckStructures = tm.os.DoFile("KM_CheckStructures"),
    UpdateUI = tm.os.DoFile("KM_UpdateUI"),
    LocalGravity = tm.os.DoFile("KM_LocalGravity"),
}
tm.os.Log("")