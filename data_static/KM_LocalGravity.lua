local KartMakers = {
    LocalGravity = {}
}

function Execute(playerId)
    local Profiling_local_gravity_start_time = tm.os.GetRealtimeSinceStartup()
    -- Check if player is in a seat
    if not tm.players.IsPlayerInSeat(playerId) then return end

    local seatBlock = tm.players.GetPlayerSeatBlock(playerId)

    local structure = seatBlock.GetStructure()

    local weight = Player_Data[playerId] and Player_Data[playerId].total_weight
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

    local Magnet_Fling_Duration = Magnet_Fling_Duration * 60

    if hit and hit.DidHit() then
        local hitNormal = hit.GetHitNormal()

        --tm.os.Log("Ground normal: " .. tostring(hitNormal))
        -- 0.33
        if Local_Gravity==true then structure.AddForce(worldDown.x * gravityStrength, worldDown.y * gravityStrength, worldDown.z * gravityStrength) end
        if Magnet_Fling==false then return end
        Player_Data[playerId].HasGroundContact = true
        if Player_Data[playerId].magnet_duration > 0 then
            Player_Data[playerId].magnet_duration = 0
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Stop", tm.players.GetPlayerGameObject(playerId))
        end
    else
        if Player_Data[playerId].HasGroundContact==true then
            if Magnet_Fling==true then
            Player_Data[playerId].magnet_duration = Magnet_Fling_Duration -- Duration in mod updates (60 = 1 second) magnet fling lasts for
            if Profiling>0 then tm.os.Log(tm.players.GetPlayerName(playerId).. " got magnet fling") end
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Start", tm.players.GetPlayerGameObject(playerId))
            end
        else
            structure.AddForce(0, -gravityStrength, 0)
        end
        Player_Data[playerId].HasGroundContact = false
    end

    if Player_Data[playerId].magnet_duration > 0 then
        local magnet_remaining = Player_Data[playerId].magnet_duration / Magnet_Fling_Duration
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
        local multiplier = gravityStrength * easing*Magnet_Fling_Strength
        --tm.os.Log(string.format("%0.2f", easing)*100 .. "% provides ".. string.format("%0.2f", multiplier).. " multiplier")

        --tm.os.Log(tm.players.GetPlayerName(playerId).. " currently has ".. string.format("%0.1f", Player_Data[playerId].magnet_duration/60) .. " seconds magnet duration left @ ".. string.format("%0.1f", easing*100) .. "%")

        local worldMagnet = tm.vector3.Lerp(seatBlock.Forward(), seatBlock.TransformDirection(tm.vector3.Create(0, -1, 0)), magnet_remaining) -- Switch "magnet_remaining" to "easing" to use ease in/out instead of linear
        structure.AddForce(worldMagnet.x * multiplier, worldMagnet.y * multiplier, worldMagnet.z * multiplier)
        
        Player_Data[playerId].magnet_duration = Player_Data[playerId].magnet_duration - 1
        if Player_Data[playerId].magnet_duration==0 then
            tm.audio.PlayAudioAtGameobject("Block_Magnet_Stop", tm.players.GetPlayerGameObject(playerId))
        end
    end

    if Profiling==1 then
        Profiling_local_gravity_time = Profiling_local_gravity_time + tm.os.GetRealtimeSinceStartup()-Profiling_local_gravity_start_time
    end
end

tm.os.Log("KartMakers.LocalGravity is now loaded")
return KartMakers.LocalGravity