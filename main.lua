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

    -- hinge having no drag is debatable cuz it honestly doesnt matter much
    PFB_SmallHinge = "decoration",

    -- pipes suck for aerodynamics as decoration pieces but if rainless is reading this,
    -- the intention is for pipes to have the same drag as 2x1x1 wedges
    -- however i have no clue how much drag it has so for now it will be zero drag
    PFB_ModularTubeSystem_Tube1 = "decoration",
    PFB_ModularTubeSystem_Skewe = "decoration",
    PFB_ModularTubeSystem_TubeE = "decoration",
    PFB_ModularTubeSystem_Tube3 = "decoration",
    PFB_LightFront = "decoration",
    PFB_LightFront_V2 = "decoration",
    PFB_PopupHeadlightBlock = "decoration",
    PFB_MilitaryHeadlights = "decoration",
    PFB_CityHeadlights = "decoration",
    PFB_BajaLEDs = "decoration",
    PFB_CameraBlock = "decoration",

    -- no drag for the seats
    PFB_GokartSeat = "seat",
    PFB_InputSeat = "seat",
    PFB_ArmouredSeat = "seat",
    PFB_CarSeat = "seat",

    -- if you have any ideas for other pieces to reduce or no drag feel free to put them here if they are decorative parts on your kart
    -- note to self: find a way to boost performance of bikes because they are severely underpowered

    dragon_engine = "engine"
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
                            b.SetBuoyancy(9) -- set bouyancy for wheels
                        end
                        if value == "4x1x1" then
                            b.SetBuoyancy(32)
                            b.SetDragAll(0, 0, 0, 0, 0, 0) -- 0 drag pistons and skis
                        end
                        if value == "seat" then
                            b.setDragAll(0, 0, 0, 0, 0, 0) -- 0 drag 
                        end
                        if value == "decoration" then
                            b.setDragAll(0, 0, 0, 0, 0, 0) -- 0 drag for now, in the future make it the same as 2x1x1 wedge
                        end
                        --if value == "engine" then
                            --if color = blah
                                --boost engine power
                        --end

                        totalbuoyancy = totalbuoyancy + math.floor(b.GetBuoyancy()*50)/10

                    end
                end
            end
            tm.playerUI.AddUILabel(p.playerId, "total", totalbuoyancy.. "kg total vehicle buoyancy")


            if tm.players.GetPlayerSelectBlockInBuild(p.playerId)~=nil then
                tm.playerUI.AddUILabel(p.playerId, "spacer", "")
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-name", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetName())
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-color", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetSecondaryColor())
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-mass", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetMass()*5 .. "kg")
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-buoyancy", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetBuoyancy()*5 .. "kg buoyancy")
                tm.playerUI.AddUILabel(p.playerId, "selectedblock-health", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetCurrentHealth().. " health")

                if tm.players.GetPlayerSelectBlockInBuild(p.playerId).IsEngineBlock() then tm.playerUI.AddUILabel(p.playerId, "selectedblock-enginepower", tm.players.GetPlayerSelectBlockInBuild(p.playerId).GetEnginePower().. " enginepower") end
            end
        end
    end
end
