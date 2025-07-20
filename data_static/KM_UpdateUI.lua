local KartMakers = {
    UpdateUI = {}
}

local error_sound = "UI_General_Toggle_Click"
KartMakers.UpdateUI.Execute = function(playerId)
    local Profiling_ui_start_time = tm.os.GetRealtimeSinceStartup()

    -- If they're not in build mode, remove the ui and end the function
    if not tm.players.GetPlayerIsInBuildMode(playerId) then
        -- Don't do what i just did for the conditions in the following if check. It's really dumb and the line is so long
        if Player_Data[playerId].ui_visible==true or Player_Data[playerId].selected_block_ui_visible == true or Player_Data[playerId].too_many_engines_ui_visible == true or Player_Data[playerId].banned_blocks_ui_visible == true or Player_Data[playerId].wheels_error_ui_visible == true or Player_Data[playerId].thrust_error_ui_visible == true then
            KartMakers.UpdateUI.ClearUIWindow(playerId)
            KartMakers.UpdateUI.ClearBuildModeSubtleMessages(playerId)
        end
        return
    end

    if Player_Data[playerId].build_mode_subtle_message_data.visible==false then
        KartMakers.UpdateUI.AddBuildModeSubtleMessages(playerId)
    end

    -- If they're in build mode, do all of the below

    -- Banned blocks error ui
    if Player_Data[playerId].banned_blocks_ui_visible==true then -- Remove banned blocks ui if it actually exists
        Player_Data[playerId].banned_blocks_ui_visible = false
        tm.playerUI.RemoveUI(playerId, "error.banned_blocks")
        for i = 1,Player_Data[playerId].banned_blocks_ui_size do
            tm.playerUI.RemoveUI(playerId, "error.banned_blocks-".. i)
        end
    end
    if Player_Data[playerId].has_banned_blocks==true then -- If they have banned blocks, generate ui
        tm.playerUI.AddUILabel(playerId, "error.banned_blocks", "<b><color=#E22>Your kart has banned blocks!</color></b>")
        Player_Data[playerId].banned_blocks_ui_size = 0
        for i,_ in ipairs(Player_Data[playerId].banned_blocks) do
            tm.playerUI.AddUILabel(playerId, "error.banned_blocks-".. i, "<i>".. Player_Data[playerId].banned_blocks[i].. "</i>")
            Player_Data[playerId].banned_blocks_ui_size = Player_Data[playerId].banned_blocks_ui_size + 1
        end
        Player_Data[playerId].banned_blocks_ui_visible = true
        tm.audio.PlayAudioAtGameobject(error_sound, tm.players.GetPlayerGameObject(playerId))
        return
    end

    -- Too many engines error ui
    if Player_Data[playerId].too_many_engines_ui_visible==true then -- Check if too many engines ui actually exists
        tm.playerUI.RemoveUI(playerId, "error.too_many_engines")
        Player_Data[playerId].too_many_engines_ui_visible = false
    end
    if #Player_Data[playerId].engines>1 then -- If the player has more than one engine, display the "too many engines" error
        tm.playerUI.AddUILabel(playerId, "error.too_many_engines", "<b><color=#E22>You can only have one engine!</color></b>")
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, Player_Data[playerId].build_mode_subtle_message_data[1].message, "You can only have one engine!")
        Player_Data[playerId].too_many_engines_ui_visible = true
        tm.audio.PlayAudioAtGameobject(error_sound, tm.players.GetPlayerGameObject(playerId))
        return
    end

    -- Wheels error error ui
    if Player_Data[playerId].wheels_error_ui_visible==true then -- Check if too many engines ui actually exists
        tm.playerUI.RemoveUI(playerId, "error.wheels_error")
        Player_Data[playerId].wheels_error_ui_visible = false
    end
    if Player_Data[playerId].wheels>0 then
        if Player_Data[playerId].wheels<Minimum_Wheels or Player_Data[playerId].wheels>6 then -- If the player doesn't have 3-6 wheels, display the "wheels error" error
            tm.playerUI.AddUILabel(playerId, "error.wheels_error", "<b><color=#E22>You must have 3-6 wheels!</color></b>")
            Player_Data[playerId].wheels_error_ui_visible = true
            -- UI_General_Toggle_Click
            tm.audio.PlayAudioAtGameobject(error_sound, tm.players.GetPlayerGameObject(playerId))
            return
        end
    end

    -- Too much thrust error ui
    if Player_Data[playerId].thrust_error_ui_visible==true then -- Check if too many engines ui actually exists
        tm.playerUI.RemoveUI(playerId, "error.thrust_error")
        Player_Data[playerId].thrust_error_ui_visible = false
    end
    if Player_Data[playerId].total_thrust>Max_Thruster_Power then
        tm.playerUI.AddUILabel(playerId, "error.thrust_error", "<b><color=#E22>You cannot have >".. Max_Thruster_Power.. " thrust!</color></b>")
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, Player_Data[playerId].build_mode_subtle_message_data[2].message, "<color=#F00>".. tostring(Player_Data[playerId].total_thrust).. "/".. Max_Thruster_Power.. " power")
        Player_Data[playerId].thrust_error_ui_visible = true
        -- UI_General_Toggle_Click
        tm.audio.PlayAudioAtGameobject(error_sound, tm.players.GetPlayerGameObject(playerId))
        return
    end

    if Player_Data[playerId].build_mode_subtle_message_data.visible==true then
        KartMakers.UpdateUI.UpdateBuildModeSubtleMessages(playerId)
    end

    -- Build mode ui
    if Player_Data[playerId].ui_visible == true then
        if Player_Data[playerId].has_banned_blocks==false then
            if Player_Data[playerId].total_engines<2 then
                tm.playerUI.SetUIValue(playerId, "total_buoyancy", string.format("%.1f", Player_Data[playerId].total_buoyancy).. "kg total vehicle buoyancy")
                tm.playerUI.SetUIValue(playerId, "total_weight", string.format("%.1f", Player_Data[playerId].total_weight).. "kg total vehicle weight")

                local block = tm.players.GetPlayerSelectBlockInBuild(playerId)
                if block~=nil then
                    -- Get hex code of the selected block's secondary color
                    local color = block.GetSecondaryColor()
                    local rgb = (color.R()*255 * 0x10000) + (color.G()*255 * 0x100) + color.B()*255
                    local shex = string.format("%06x", rgb)
                    
                    if Player_Data[playerId].selected_block_ui_visible==true then
                        tm.playerUI.SetUIValue(playerId, "selected_block.name", string.sub(block.GetName(), 5, -10))
                        tm.playerUI.SetUIValue(playerId, "selected_block.mass", "Weight: ".. string.format("%0.1f", block.GetMass()*5) .. "kg")
                        tm.playerUI.SetUIValue(playerId, "selected_block.buoyancy", "Buoyancy: ".. string.format("%0.1f", block.GetBuoyancy()*5) .. "kg")
                        tm.playerUI.SetUIValue(playerId, "selected_block.secondary_color", "Secondary color: <color=#".. shex.. ">██</color> #".. shex)
                        if block.IsEngineBlock() then
                            local engine_power = block.GetEnginePower()
                            tm.playerUI.SetUIValue(playerId, "selected_block.engine_power", Player_Data[playerId].selected_engine_cc.. "cc | ".. engine_power.. " power")
                        else
                            tm.playerUI.SetUIValue(playerId, "selected_block.engine_power", "<color=#666>N/A</color>") 
                        end
                    else
                        Player_Data[playerId].selected_block_ui_visible = true
                        tm.playerUI.AddUILabel(playerId, "newline", "")
                        tm.playerUI.AddUILabel(playerId, "selected_block.name", string.sub(tm.players.GetPlayerSelectBlockInBuild(playerId).GetName(), 5, -10))
                        tm.playerUI.AddUILabel(playerId, "selected_block.mass", "Weight: ".. string.format("%0.1f", tm.players.GetPlayerSelectBlockInBuild(playerId).GetMass()*5) .. "kg")
                        tm.playerUI.AddUILabel(playerId, "selected_block.buoyancy", "Buoyancy: ".. string.format("%0.1f", tm.players.GetPlayerSelectBlockInBuild(playerId).GetBuoyancy()*5) .. "kg")
                        tm.playerUI.AddUILabel(playerId, "selected_block.secondary_color", "Secondary color: <color=#".. shex.. ">██</color> #".. shex)
                        if block.IsEngineBlock() then
                            local engine_power = block.GetEnginePower()
                            tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", Player_Data[playerId].selected_engine_cc.. "cc | ".. engine_power.. " power")
                        else
                            tm.playerUI.AddUILabel(playerId, "selected_block.engine_power", "<color=#666>N/A</color>") 
                        end
                    end
                else
                    if Player_Data[playerId].selected_block_ui_visible==true then
                        Player_Data[playerId].selected_block_ui_visible = false
                        tm.playerUI.RemoveUI(playerId, "newline")
                        tm.playerUI.RemoveUI(playerId, "selected_block.name")
                        tm.playerUI.RemoveUI(playerId, "selected_block.mass")
                        tm.playerUI.RemoveUI(playerId, "selected_block.buoyancy")
                        tm.playerUI.RemoveUI(playerId, "selected_block.secondary_color")
                        tm.playerUI.RemoveUI(playerId, "selected_block.engine_power")
                    end
                end
            end
        end
    else
        Player_Data[playerId].ui_visible = true
        tm.playerUI.AddUILabel(playerId, "total_buoyancy", string.format("%.1f", Player_Data[playerId].total_buoyancy).. "kg total vehicle buoyancy")
        tm.playerUI.AddUILabel(playerId, "total_weight", string.format("%.1f", Player_Data[playerId].total_weight).. "kg total vehicle weight") -- Inaccurate vehicle weight isn't a bug; steering hinge has a misleading in-game weight value   
    end

    if Profiling==1 then
        local endtime = tm.os.GetRealtimeSinceStartup()
        Profiling_ui_time = Profiling_ui_time + endtime-Profiling_ui_start_time
    end
end

KartMakers.UpdateUI.AddBuildModeSubtleMessages = function(playerId)
    Player_Data[playerId].build_mode_subtle_message_data[1].message = tm.playerUI.AddSubtleMessageForPlayer(playerId, "", tostring(Player_Data[playerId].selected_engine_cc).. "cc", 32767, "km_engine")
    Player_Data[playerId].build_mode_subtle_message_data[2].message = tm.playerUI.AddSubtleMessageForPlayer(playerId, "", tostring(Player_Data[playerId].total_thrust).. "/".. Max_Thruster_Power.. " thrust", 32767, "km_thrust")
    Player_Data[playerId].build_mode_subtle_message_data.visible = true
end

KartMakers.UpdateUI.UpdateBuildModeSubtleMessages = function(playerId)
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, Player_Data[playerId].build_mode_subtle_message_data[1].message, tostring(Player_Data[playerId].selected_engine_cc).. "cc")
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, Player_Data[playerId].build_mode_subtle_message_data[2].message, tostring(Player_Data[playerId].total_thrust).. "/".. Max_Thruster_Power.. " power")
end

KartMakers.UpdateUI.ClearBuildModeSubtleMessages = function(playerId)
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, Player_Data[playerId].build_mode_subtle_message_data[1].message)
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, Player_Data[playerId].build_mode_subtle_message_data[2].message)
    Player_Data[playerId].build_mode_subtle_message_data[1].message = nil
    Player_Data[playerId].build_mode_subtle_message_data[2].message = nil
    Player_Data[playerId].build_mode_subtle_message_data.visible = false
end

KartMakers.UpdateUI.ClearUIWindow = function(playerId)
    if Player_Data[playerId].ui_visible == true then
        tm.playerUI.RemoveUI(playerId, "total_weight")
        tm.playerUI.RemoveUI(playerId, "total_buoyancy")
        if Player_Data[playerId].banned_blocks_ui_visible == true then
            for i = 1,Player_Data[playerId].banned_blocks_ui_size do
                tm.playerUI.RemoveUI(playerId, "error.banned_blocks-".. i)
            end
            tm.playerUI.RemoveUI(playerId, "error.banned_blocks")
            Player_Data[playerId].banned_blocks_ui_visible = false
        end
        if Player_Data[playerId].too_many_engines_ui_visible == true then
            tm.playerUI.RemoveUI(playerId, "error.too_many_engines")
            Player_Data[playerId].too_many_engines_ui_visible = false
        end
        if Player_Data[playerId].wheels_error_ui_visible == true then
            tm.playerUI.RemoveUI(playerId, "error.wheels_error")
            Player_Data[playerId].wheels_error_ui_visible = false
        end
        if Player_Data[playerId].thrust_error_ui_visible == true then
            tm.playerUI.RemoveUI(playerId, "error.thrust_error")
            Player_Data[playerId].thrust_error_ui_visible = false
        end
        if Player_Data[playerId].selected_block_ui_visible == true then
            tm.playerUI.RemoveUI(playerId, "selected_block.engine_power")
            tm.playerUI.RemoveUI(playerId, "selected_block.buoyancy")
            tm.playerUI.RemoveUI(playerId, "selected_block.mass")
            tm.playerUI.RemoveUI(playerId, "selected_block.secondary_color")
            tm.playerUI.RemoveUI(playerId, "selected_block.name")
            tm.playerUI.RemoveUI(playerId, "newline")
            Player_Data[playerId].selected_block_ui_visible = false
        end
        Player_Data[playerId].ui_visible = false
    end
end

tm.os.Log("KartMakers.UpdateUI is now loaded")
return KartMakers.UpdateUI