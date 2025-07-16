local KartMakers = {
    CheckStructures = {}
}

KartMakers.CheckStructures.Execute = function(playerId)
    local Profiling_structure_checking_start_time = tm.os.GetRealtimeSinceStartup()
    if tm.players.GetPlayerIsInBuildMode(playerId) then
        local live_block_count = 0
        local structures = tm.players.GetPlayerStructuresInBuild(playerId)
        for _,structure in ipairs(structures) do
            live_block_count = live_block_count + #structure.GetBlocks()
        end
        if Player_Data[playerId].has_banned_blocks==false and #Player_Data[playerId].engines<2 and Player_Data[playerId].total_thrust<=300 then
            for i,_ in ipairs(Player_Data[playerId].engines) do
                --tm.os.Log("Checking engine #".. i)
                if Player_Data[playerId].engines[i].block.Exists() then
                    local block = Player_Data[playerId].engines[i].block
                    local power = 0
                    --tm.os.Log("  Engine exists, calculating power...")
                    if Player_Data[playerId].wheels>=Minimum_Wheels and Player_Data[playerId].wheels<=6 then
                        --tm.os.Log("    Wheel check passed")
                        for j,_ in ipairs(Engine_Power_List) do
                            --tm.os.Log("      Checking engine type #".. j)
                            if string.sub(block.GetName(), 5, -10) == Engine_Power_List[j].name then
                                power = Engine_Power_List[j].cc*22.22
                                Player_Data[playerId].selected_engine_cc = Engine_Power_List[j].cc
                                --tm.os.Log(        "Engine is type #".. j.. " | Calculated power is now ".. power)
                                break
                            end
                        end
                    else
                        --tm.os.Log("    Wheel check failed")
                    end
                    if block.GetEnginePower() ~= power then
                        tm.os.Log("  Engine power was updated. Current power: ".. block.GetEnginePower().. " | Calculated power: ".. power)
                        if Profiling>0 then
                            tm.os.Log(tm.players.GetPlayerName(playerId).. " (".. playerId.. ")'s engine power is out of sync, updating...")
                        end
                        tm.audio.PlayAudioAtGameobject("Build_attach_Weapon", tm.players.GetPlayerGameObject(playerId))
                        block.SetEnginePower(power)
                        Player_Data[playerId].engines[#Player_Data[playerId].engines].power = block.GetEnginePower()
                    else
                        --tm.os.Log("  Engine power is identical. Current power: ".. block.GetEnginePower().. " | Calculated power: ".. power)
                    end
                else
                    tm.os.Log("  Engine does not exist, forcing cache refresh...")
                    Player_Data[playerId].block_count = -1
                end
            end
        end
        if live_block_count ~= Player_Data[playerId].block_count then
            if Profiling>0 then
                tm.os.Log("Build was updated for ".. tm.players.GetPlayerName(playerId).. " (".. playerId.. "), updating data...")
                --tm.os.Log("Build has ".. live_block_count.. " blocks right now")
                --tm.os.Log("Build had ".. Player_Data[playerId].block_count.. " blocks")
            end

            Player_Data[playerId].block_count = live_block_count
            tm.audio.PlayAudioAtGameobject("Build_attach_Flag", tm.players.GetPlayerGameObject(playerId))
            Player_Data[playerId].total_buoyancy = 0
            Player_Data[playerId].total_weight = 0
            Player_Data[playerId].total_thrust = 0
            Player_Data[playerId].has_banned_blocks = false
            Player_Data[playerId].banned_blocks = {}
            Player_Data[playerId].total_engines = 0
            Player_Data[playerId].selected_engine_cc = 0
            Player_Data[playerId].wheels = 0
            Player_Data[playerId].engines = {}
            for _,structure in ipairs(structures) do
                local blocks = structure.GetBlocks()
                for i,block in pairs(blocks) do
                    local value = Block_Types[string.sub(block.GetName(), 5, -10)]

                    if value == "2x2x1" then -- gokart wheel
                        block.SetBuoyancy(4) -- multiply buoyancy by 5 to convert to kg
                        Player_Data[playerId].wheels = Player_Data[playerId].wheels + 1
                    end
                    if value == "3x3x1" then
                        block.SetBuoyancy(9)
                        Player_Data[playerId].wheels = Player_Data[playerId].wheels + 1
                    end
                    if value == "3x3x2" then
                        block.SetBuoyancy(9)
                        Player_Data[playerId].wheels = Player_Data[playerId].wheels + 1
                    end
                    if value == "5x5x2" then -- truck wheel
                        block.SetBuoyancy(12)
                        Player_Data[playerId].wheels = Player_Data[playerId].wheels + 1
                    end
                    if value == "7x7x4" then -- monster truck wheel
                        block.SetBuoyancy(20) -- multiply buoyancy by 5 to convert to kg
                        Player_Data[playerId].wheels = Player_Data[playerId].wheels + 1
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
                        Player_Data[playerId].total_engines = Player_Data[playerId].total_engines + 1
                        Player_Data[playerId].engines[#Player_Data[playerId].engines+1] = {block=nil,power=nil}
                        Player_Data[playerId].engines[#Player_Data[playerId].engines].block = block
                        Player_Data[playerId].engines[#Player_Data[playerId].engines].power = block.GetEnginePower()
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
                        Player_Data[playerId].has_banned_blocks = true
                        table.insert(Player_Data[playerId].banned_blocks, string.sub(block.GetName(), 5, -10))
                    end

                    if block.IsJetBlock() then
                        Player_Data[playerId].total_thrust = Player_Data[playerId].total_thrust + block.GetJetPower()
                    end

                    -- multiply mass by 5 to convert to kg
                    Player_Data[playerId].total_buoyancy = Player_Data[playerId].total_buoyancy + block.GetBuoyancy()*5
                    Player_Data[playerId].total_weight = Player_Data[playerId].total_weight + block.GetMass()*5
                end
                for i,_ in ipairs(Player_Data[playerId].engines) do
                    local block = Player_Data[playerId].engines[i].block
                    block.SetEnginePower(0) -- Set to zero so if there's an invalid kart setup it remains as zero
                    if #Player_Data[playerId].banned_blocks==0 then
                        for j,_ in ipairs(Engine_Power_List) do
                            if string.sub(block.GetName(), 5, -10) == Engine_Power_List[j].name then
                                block.SetEnginePower(Engine_Power_List[j].cc*22.22)
                                block.SetMass(Engine_Power_List[j].weight)
                                Player_Data[playerId].engines[#Player_Data[playerId].engines].power = block.GetEnginePower()
                                Player_Data[playerId].selected_engine_cc = Engine_Power_List[j].cc
                                --tm.os.Log("Found engine match! Engine power is now ".. block.GetEnginePower())
                                break
                            end
                        end
                    else
                        for _,block in ipairs(blocks) do
                            local value = Block_Types[string.sub(block.GetName(), 5, -10)]
                            if value == "engine" then
                                block.SetEnginePower(0)
                            end
                        end
                    end
                end
                if Player_Data[playerId].has_banned_blocks == true or Player_Data[playerId].wheels<Minimum_Wheels or Player_Data[playerId].wheels>6 or Player_Data[playerId].total_thrust>Max_Thruster_Power then
                    for _,block in ipairs(blocks) do
                        local value = Block_Types[string.sub(block.GetName(), 5, -10)]
                        if value == "engine" then
                            block.SetEnginePower(0)
                        end
                    end
                end
            end
        end
        if Profiling==1 then
            Profiling_structure_checking_time = Profiling_structure_checking_time + tm.os.GetRealtimeSinceStartup()-Profiling_structure_checking_start_time
        end
    end
end

tm.os.Log("KartMakers.CheckStructures is now loaded")
return KartMakers.CheckStructures