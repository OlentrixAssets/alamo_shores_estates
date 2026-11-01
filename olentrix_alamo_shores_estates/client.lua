local MIN, MAX = vector3(-29.73, 3559.02, 0.0), vector3(135.49, 3772.85, 120.0)
local CENTRE = vector3(52.88, 3665.94, 39.0)

local nonCreation = false

CreateThread(function()
    AddScenarioBlockingArea(MIN.x, MIN.y, MIN.z, MAX.x, MAX.y, MAX.z, false, true, true, true)
    while true do
        local p = GetEntityCoords(PlayerPedId())
        local near = #(p.xy - CENTRE.xy) < 250.0
        if not near and nonCreation then
            ClearPedNonCreationArea()
            nonCreation = false
        end
        local muted = IsAudioSceneActive('MP_POSITIONED_RADIO_MUTE_SCENE')
        if near and not muted then StartAudioScene('MP_POSITIONED_RADIO_MUTE_SCENE')
        elseif not near and muted then StopAudioScene('MP_POSITIONED_RADIO_MUTE_SCENE') end
        if near then
            SetPedNonCreationArea(MIN.x, MIN.y, MIN.z, MAX.x, MAX.y, MAX.z)
            nonCreation = true
            for _, ped in ipairs(GetGamePool('CPed')) do
                if not IsPedAPlayer(ped) and not IsEntityAMissionEntity(ped) then
                    local c = GetEntityCoords(ped)
                    if c.x > MIN.x and c.x < MAX.x and c.y > MIN.y and c.y < MAX.y and NetworkHasControlOfEntity(ped) then
                        SetEntityAsMissionEntity(ped, true, true)
                        DeleteEntity(ped)
                    end
                end
            end
        end
        Wait(near and 1000 or 3000)
    end
end)

local SLIDERS = {
    { name = 'closet', model = `sc_lux_wardrobe_door`, shut = vector3(16.126, 3664.597, 39.767), open = vector3(16.753, 3663.682, 39.767),
      heading = -55.57, speed = 0.8, reach = 1.6, label = 'the closet' },
    { name = 'exit', model = `sc_lux_exit_door`, shut = vector3(-146.927, 3647.243, 39.43), open = vector3(-146.927, 3647.243, 41.48),
      heading = 48.41, speed = 0.6, reach = 2.6, label = 'the door' },
}
for _, s in ipairs(SLIDERS) do s.at = 0.0 end

CreateThread(function()
    while true do
        local p = GetEntityCoords(PlayerPedId())
        local near = false
        for _, s in ipairs(SLIDERS) do
            local d = #(p - s.shut)
            if d < 60.0 and not s.obj then
                RequestModel(s.model)
                while not HasModelLoaded(s.model) do Wait(50) end
                s.at = GlobalState['ase_slide_' .. s.name] and 1.0 or 0.0
                local at = s.shut + (s.open - s.shut) * s.at
                s.obj = CreateObjectNoOffset(s.model, at.x, at.y, at.z, false, false, false)
                SetEntityHeading(s.obj, s.heading); FreezeEntityPosition(s.obj, true)
                SetModelAsNoLongerNeeded(s.model)
            elseif d > 80.0 and s.obj then
                DeleteObject(s.obj); s.obj = nil
            end
            if s.obj then
                near = true
                local open = GlobalState['ase_slide_' .. s.name]
                local want = open and 1.0 or 0.0
                if math.abs(want - s.at) > 0.001 then
                    local step = s.speed * 0.016 / #(s.open - s.shut)
                    s.at = want > s.at and math.min(want, s.at + step) or math.max(want, s.at - step)
                    local at = s.shut + (s.open - s.shut) * s.at
                    SetEntityCoordsNoOffset(s.obj, at.x, at.y, at.z, false, false, false)
                end
                if d < s.reach and math.abs(p.z - s.shut.z - 1.0) < 1.6 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName((open and '~INPUT_CONTEXT~ Shut ' or '~INPUT_CONTEXT~ Open ') .. s.label)
                    EndTextCommandDisplayHelp(0, false, false, -1)
                    if IsControlJustReleased(0, 38) then TriggerServerEvent('olentrix_alamo_shores_estates:slide', s.name) end
                end
            end
        end
        Wait(near and 0 or 1000)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, s in ipairs(SLIDERS) do if s.obj then DeleteObject(s.obj) end end
end)
