local NAMES = { closet = true, exit = true }
local last = {}
for n in pairs(NAMES) do GlobalState['ase_slide_' .. n] = false end
RegisterNetEvent('olentrix_alamo_shores_estates:slide', function(name)
    if type(name) ~= 'string' or not NAMES[name] then return end
    if GetGameTimer() - (last[name] or 0) < 1000 then return end
    last[name] = GetGameTimer()
    GlobalState['ase_slide_' .. name] = not GlobalState['ase_slide_' .. name]
end)
