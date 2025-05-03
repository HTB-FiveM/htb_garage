RegisterNetEvent("htb_garage:ShowClientNotification")
AddEventHandler("htb_garage:ShowClientNotification", function(message)
    FrameworkCtx:ShowNotification(message)
end)

--- Returns a table with the future game time after adding n hours.
-- @param n number of hours to add (can be fractional)
-- @return { hours=int, minutes=int, seconds=int, dayOverflow=int }
function GetGameTimePlus(hours)
    -- fetch current in‑game time
    local h = GetClockHours()
    local m = GetClockMinutes()
    local s = GetClockSeconds()

    -- total seconds since midnight
    local currentSec = h * 3600 + m * 60 + s
    local addSec     = math.floor(hours * 3600)
    local totalSec   = currentSec + addSec

    -- compute overflow days and wrap‑around seconds
    local dayOverflow = math.floor(totalSec / (24 * 3600))
    local wrapSec     = totalSec % (24 * 3600)

    -- convert back to h:m:s
    local newH = math.floor(wrapSec / 3600)
    local newM = math.floor((wrapSec % 3600) / 60)
    local newS = wrapSec % 60

    return {
        hours       = newH,
        minutes     = newM,
        seconds     = newS,
        dayOverflow = dayOverflow,  -- how many days you rolled past
    }
end

--- Find the first vehicle whose plate matches `plateText`
--- @param plateText string
--- @return number|nil vehicleEntity
function GetVehicleByPlate(plateText)
    -- get all vehicles currently streamed in for this client
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(veh) then
            -- strip spaces/case if you like
            if GetVehicleNumberPlateText(veh) == plateText then
                return veh
            end
        end
    end
    return nil
end



RegisterCommand('coords_htb', function()
    local ped = PlayerPedId()
    -- Get current position
    local x, y, z = table.unpack(GetEntityCoords(ped))
    -- Get current heading
    local heading = GetEntityHeading(ped)

    -- Format as vector3
    local posVec = vector3(x, y, z)

    -- Print to the client console
    print(('[coords] %s, heading: %.2f'):format(posVec, heading))

    -- Optional: show in chat as well
    TriggerEvent('chat:addMessage', {
        color = { 255, 240, 0},
        args = { 'Coords', ('%s | heading: %.2f'):format(posVec, heading) }
    })
end, false)

-- Optional: bind to a key (e.g. F5)
RegisterKeyMapping('coords_htb', 'Dump current coords & heading', 'keyboard', 'F5')
