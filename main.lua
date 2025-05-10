-- offroad_wheel = "PFB_WheelStandard"
-- racing_wheel = "PFB_WheelSlick"
-- monster_truck_wheel = "PFB_MonsterTruckWheelBlock"
-- gokart_wheel = "PFB_GocartWheel"
-- slim_wheel = "PFB_SlimWheel"
-- drag_racing_wheel = "PFB_DragRacingWheel"
-- truck_wheel = "PFB_TruckWheel"
-- spiked_wheel = "PFB_SpikedWheel"
-- standard_car_wheel = "PFB_CarWheel_3x3x1"
-- motorcycle_wheel = "PFB_MotorCycleWheel"
-- airborne_landing_wheels = "PFB_TopMountedLandingWheel"
-- skis = "PFB_WaterSki"
-- piston = "PFB_Piston"

-- bulldawg_engine = "PFB_EngineBasic"
-- raw_engine = "PFB_EngineOlSchool"
-- dragon_engine = "PFB_EngineNinja"

tm.os.Log("KartMakers block modification mod enabled")

local block_types = {
    PFB_WheelStandard = "3x3x2",
    PFB_WheelSlick = "3x3x2",
    PFB_MonsterTruckWheelBlock = "7x7x4",
    PFB_GocartWheel = "2x2x1",
    PFB_SlimWheel = "3x3x1",
    PFB_DragRacingWheel = "5x5x4",
    PFB_TruckWheel = "5x5x2",
    PFB_SpikedWheel = "3x3x2",
    PFB_CarWheel_3x3x1 = "3x3x1",
    PFB_MotorCycleWheel = "3x3x1",
    PFB_TopMountedLandingWheel = "3x2x2",
    PFB_WaterSki = "4x1x1",
    PFB_Piston = "4x1x1",

    -- bulldawg_engine = "PFB_EngineBasic",
    -- raw_engine = "PFB_EngineOlSchool",
    -- dragon_engine = "PFB_EngineNinja"
}

function update()
    local players = tm.players.CurrentPlayers()
    for _, p in ipairs(players) do
        tm.playerUI.ClearUI(p.playerId)
        -- If the player isn't in build mode, ignore them
        if tm.players.GetPlayerIsInBuildMode(p.playerId) then
            local structures = tm.players.GetPlayerStructuresInBuild(p.playerId)
            totalbuoyancy = 0
            for _, s in ipairs(structures) do
                local blocks = s.GetBlocks()
                for _, b in ipairs(blocks) do
                    if b.Exists() == true then
                        b.SetHealth(2048)

                        local value = block_types[string.sub(b.GetName(), 0, -10)]
                        if value == "3x3x1" or value == "3x3x2" then
                            b.SetBuoyancy(9)
                        end
                        if value == "4x1x1" then
                            b.SetBuoyancy(32)
                            b.SetDragAll(0, 0, 0, 0, 0, 0) -- 0 drag pistons and skis
                        end

                        totalbuoyancy = totalbuoyancy + math.floor(b.GetBuoyancy()*50)/10

                    end
                end
            end
            tm.playerUI.AddUILabel(p.playerId, "total", totalbuoyancy.. "kg total vehicle buoyancy")


            if tm.players.GetPlayerSelectBlockInBuild(p.playerId)~=nil then
                tm.playerUI.AddUILabel(p.playerId, "spacer", "")
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-name", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetName())
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-mass", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetMass()*5 .. "kg")
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-buoyancy", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetBuoyancy()*5 .. "kg buoyancy")
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-health", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetCurrentHealth().. " health")

                if tm.players.GetPlayerSelectBlockInBuild(p.playerId).IsEngineBlock() then tm.playerUI.AddUILabel(p.playerId, "selectedblock-enginepower", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetEnginePower().. " enginepower") end
            end
        end
    end
end