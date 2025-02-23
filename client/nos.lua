local NitrousActivated = false
local NitrousBoost = 35.0
local VehicleNitrous = {}
local Fxs = {}

local vehicles = {}
local particles = {}
local Purged = {}

local function trim(value)
	if not value then return nil end
    return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('nitrous:GetNosLoadedVehs', function(vehs)
        VehicleNitrous = vehs
    end)
end)

RegisterNetEvent('smallresource:client:LoadNitrous', function()
    local IsInVehicle = IsPedInAnyVehicle(PlayerPedId())
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped)
    local Plate = trim(GetVehicleNumberPlateText(veh))
    if not NitrousActivated then
        if IsToggleModOn(veh, 18) then
            if IsInVehicle and not IsThisModelABike(GetEntityModel(GetVehiclePedIsIn(ped))) then
                if GetPedInVehicleSeat(veh, -1) == ped then
                        QBCore.Functions.Progressbar("use_nos", "Connecting NOS...", 1000, false, true, {
                            disableMovement = false,
                            disableCarMovement = false,
                            disableMouse = false,
                            disableCombat = true,
                        }, {}, {}, {}, function() -- Done
                            TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items['nitrous'], "remove")
                            TriggerServerEvent("QBCore:Server:RemoveItem", 'nitrous', 1)
                            local CurrentVehicle = GetVehiclePedIsIn(PlayerPedId())
                            local Plate = GetVehicleNumberPlateText(CurrentVehicle)
                            TriggerServerEvent('nitrous:server:LoadNitrous', Plate)
                            Purged[Plate]=false
                        end)
                else
                    QBCore.Functions.Notify("You cannot do that from this seat!", "error")
                end
            else
                QBCore.Functions.Notify('You\'re Not In A Car', 'error')
            end
        else
            QBCore.Functions.Notify('You need a Turbo to use NOS!', 'error')
        end
    else
        QBCore.Functions.Notify('You Already Have NOS Active', 'error')
    end
end)

local nosupdated = false

CreateThread(function()
    while true do
        local IsInVehicle = IsPedInAnyVehicle(PlayerPedId())
        local CurrentVehicle = GetVehiclePedIsIn(PlayerPedId())
        if IsInVehicle then
            local Plate = trim(GetVehicleNumberPlateText(CurrentVehicle))
            if VehicleNitrous[Plate] ~= nil then
                if VehicleNitrous[Plate].hasnitro then
                    if IsControlJustPressed(0, 36) and GetPedInVehicleSeat(CurrentVehicle, -1) == PlayerPedId() then
                        SetVehicleEnginePowerMultiplier(CurrentVehicle, NitrousBoost)
                        SetVehicleEngineTorqueMultiplier(CurrentVehicle, NitrousBoost)
                        SetEntityMaxSpeed(CurrentVehicle, 999.0)
                        NitrousActivated = true
                        CreateThread(function()
                            while NitrousActivated do
                                if VehicleNitrous[Plate].level - 1 ~= 0 then
                                    TriggerServerEvent('nitrous:server:UpdateNitroLevel', Plate, (VehicleNitrous[Plate].level - 1))
                                    TriggerEvent('hud:client:UpdateNitrous', VehicleNitrous[Plate].hasnitro,  VehicleNitrous[Plate].level, true)
                                    CreateVehicleExhaustBackfire(CurrentVehicle, 1.25)
                                else
                                    TriggerServerEvent('nitrous:server:UnloadNitrous', Plate)
                                    NitrousActivated = false
                                    SetVehicleBoostActive(CurrentVehicle, 0)
                                    SetVehicleEnginePowerMultiplier(CurrentVehicle, LastEngineMultiplier)
                                    SetVehicleEngineTorqueMultiplier(CurrentVehicle, 1.0)
                                    for index,_ in pairs(Fxs) do
                                        StopParticleFxLooped(Fxs[index], 1)
                                        TriggerServerEvent('nitrous:server:StopSync', trim(GetVehicleNumberPlateText(CurrentVehicle)))
                                        Fxs[index] = nil
                                    end
                                end
                                Wait(100)
                            end
                        end)
                    end
                    if IsControlJustReleased(0, 36) and GetPedInVehicleSeat(CurrentVehicle, -1) == PlayerPedId() then
                        if NitrousActivated then
                            local veh = GetVehiclePedIsIn(PlayerPedId())
                            SetVehicleBoostActive(veh, 0)
                            SetVehicleEnginePowerMultiplier(veh, LastEngineMultiplier)
                            SetVehicleEngineTorqueMultiplier(veh, 1.0)
                            for index,_ in pairs(Fxs) do
                                StopParticleFxLooped(Fxs[index], 1)
                                TriggerServerEvent('nitrous:server:StopSync', trim(GetVehicleNumberPlateText(veh)))
                                Fxs[index] = nil
                            end
                            TriggerEvent('hud:client:UpdateNitrous', VehicleNitrous[Plate].hasnitro,  VehicleNitrous[Plate].level, false)
                            NitrousActivated = false
                        end
                    end
                end

            if Purged[Plate]==false and IsControlJustPressed(0, 21) and GetPedInVehicleSeat(CurrentVehicle, -1) == PlayerPedId() then
                SetVehicleNitroPurgeEnabled(GetVehiclePedIsIn(PlayerPedId()), true)
                QBCore.Functions.Notify("NOS System Purging", "success")
                nit = true
                CreateThread(function()
                    while nit do
                        if VehicleNitrous[Plate].level - 1 ~= 0 then
                            TriggerServerEvent('nitrous:server:UpdateNit', Plate, (VehicleNitrous[Plate].level - 1))
                            TriggerEvent('hud:client:UpdateNitrous', VehicleNitrous[Plate].hasnitro,  VehicleNitrous[Plate].level, true)
                        else
                            TriggerServerEvent('nitrous:server:UnloadNitrous', Plate)
                            nit = false
                            for index,_ in pairs(Fxs) do
                                StopParticleFxLooped(Fxs[index], 1)
                                TriggerServerEvent('nitrous:server:StopSync', trim(GetVehicleNumberPlateText(CurrentVehicle)))
                                Fxs[index] = nil
                            end
                        end
                        Wait(100)
                    end
                end)
            end
            if IsControlJustReleased(0, 21) then 
                if nit then
                    SetVehicleNitroPurgeEnabled(GetVehiclePedIsIn(PlayerPedId()), false)
                    for index,_ in pairs(Fxs) do
                    StopParticleFxLooped(Fxs[index], 1)
                    TriggerServerEvent('nitrous:server:StopSync', trim(GetVehicleNumberPlateText(veh)))
                    Fxs[index] = nil
                    end
                    TriggerEvent('hud:client:UpdateNitrous', VehicleNitrous[Plate].hasnitro,  VehicleNitrous[Plate].level, false)
                    nit = false
                end
            end

        else
            if not nosupdated then
                TriggerEvent('hud:client:UpdateNitrous', false, nil, false)
                nosupdated = true
            end
        end

        else
            if nosupdated then
                nosupdated = false
            end
            Wait(1500)
        end
        Wait(3)
    end
end)

p_flame_location = {
	"exhaust",
	"exhaust_2",
	"exhaust_3",
	"exhaust_4",
	"exhaust_5",
	"exhaust_6",
	"exhaust_7",
	"exhaust_8",
	"exhaust_9",
	"exhaust_10",
	"exhaust_11",
	"exhaust_12",
	"exhaust_13",
	"exhaust_14",
	"exhaust_15",
	"exhaust_16",
}

ParticleDict = "veh_xs_vehicle_mods"
ParticleFx = "veh_nitrous"
ParticleSize = 1.4

CreateThread(function()
    while true do
        if NitrousActivated then
            local veh = GetVehiclePedIsIn(PlayerPedId())
            if veh ~= 0 then
                TriggerServerEvent('nitrous:server:SyncFlames', VehToNet(veh))
                SetVehicleBoostActive(veh, 1)

                for _,bones in pairs(p_flame_location) do
                    if GetEntityBoneIndexByName(veh, bones) ~= -1 then
                        if Fxs[bones] == nil then
                            RequestNamedPtfxAsset(ParticleDict)
                            while not HasNamedPtfxAssetLoaded(ParticleDict) do
                                Wait(0)
                            end
                            SetPtfxAssetNextCall(ParticleDict)
                            UseParticleFxAssetNextCall(ParticleDict)
                            Fxs[bones] = StartParticleFxLoopedOnEntityBone(ParticleFx, veh, 0.0, -0.02, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(veh, bones), ParticleSize, 0.0, 0.0, 0.0)
                        end
                    end
                end
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    while true do
        if nit then
            local veh = GetVehiclePedIsIn(PlayerPedId())
            if veh ~= 0 then
            end
        end
        Wait(0)
    end
end)

local NOSPFX = {}

RegisterNetEvent('nitrous:client:SyncFlames', function(netid, nosid)
    local veh = NetToVeh(netid)
    if veh ~= 0 then
        local myid = GetPlayerServerId(PlayerId())
        if NOSPFX[trim(GetVehicleNumberPlateText(veh))] == nil then
            NOSPFX[trim(GetVehicleNumberPlateText(veh))] = {}
        end
        if myid ~= nosid then
            for _,bones in pairs(p_flame_location) do
                if NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones] == nil then
                    NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones] = {}
                end
                if GetEntityBoneIndexByName(veh, bones) ~= -1 then
                    if NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones].pfx == nil then
                        RequestNamedPtfxAsset(ParticleDict)
                        while not HasNamedPtfxAssetLoaded(ParticleDict) do
                            Wait(0)
                        end
                        SetPtfxAssetNextCall(ParticleDict)
                        UseParticleFxAssetNextCall(ParticleDict)
                        NOSPFX[trim(GetVehicleNumberPlateText(veh))][bones].pfx = StartParticleFxLoopedOnEntityBone(ParticleFx, veh, 0.0, -0.05, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(veh, bones), ParticleSize, 0.0, 0.0, 0.0)

                    end
                end
            end
        end
    end
end)

RegisterNetEvent('nitrous:client:StopSync', function(plate)
    for k, v in pairs(NOSPFX[plate]) do
        StopParticleFxLooped(v.pfx, 1)
        NOSPFX[plate][k].pfx = nil
end
end)

RegisterNetEvent('nitrous:client:UpdateNitroLevel', function(Plate, level)
    VehicleNitrous[Plate].level = level
end)

RegisterNetEvent('nitrous:client:UpdateNit', function(Plate, level)
    VehicleNitrous[Plate].level = level -2
end)

RegisterNetEvent('nitrous:client:LoadNitrous', function(Plate)
    VehicleNitrous[Plate] = {
        hasnitro = true,
        level = 100,
    }
    local CurrentVehicle = GetVehiclePedIsIn(PlayerPedId())
    local CPlate = trim(GetVehicleNumberPlateText(CurrentVehicle))
    if CPlate == Plate then
        TriggerEvent('hud:client:UpdateNitrous', VehicleNitrous[Plate].hasnitro,  VehicleNitrous[Plate].level, false)
    end
end)

RegisterNetEvent('nitrous:client:UnloadNitrous', function(Plate)
    VehicleNitrous[Plate] = nil
    local CurrentVehicle = GetVehiclePedIsIn(PlayerPedId())
    local CPlate = trim(GetVehicleNumberPlateText(CurrentVehicle))
    if CPlate == Plate then
        NitrousActivated = false
        TriggerEvent('hud:client:UpdateNitrous', false, nil, false)
    end
end)

local vehicles = {}
local particles = {}

function SetVehicleNitroPurgeEnabled(vehicle, enabled)
    if enabled then
      local bone = GetEntityBoneIndexByName(vehicle, 'bonnet')
      local pos = GetWorldPositionOfEntityBone(vehicle, bone)
      local off = GetOffsetFromEntityGivenWorldCoords(vehicle, pos.x, pos.y, pos.z)
      local ptfxs = {}
  
      for i=0,6 do
        local leftPurge = CreateVehiclePurgeSpray(vehicle, off.x - 0.5, off.y + 0.05, off.z, 40.0, -20.0, 0.0, 0.5)
        local rightPurge = CreateVehiclePurgeSpray(vehicle, off.x + 0.5, off.y + 0.05, off.z, 40.0, 20.0, 0.0, 0.5)
  
        table.insert(ptfxs, leftPurge)
        table.insert(ptfxs, rightPurge)
      end
  
      vehicles[vehicle] = true
      particles[vehicle] = ptfxs
    else
      if particles[vehicle] and #particles[vehicle] > 0 then
        for _, particleId in ipairs(particles[vehicle]) do
          StopParticleFxLooped(particleId)
        end
      end
  
      vehicles[vehicle] = nil
      particles[vehicle] = nil
    end
end

function CreateVehiclePurgeSpray(vehicle, xOffset, yOffset, zOffset, xRot, yRot, zRot, scale)
    if not HasNamedPtfxAssetLoaded("core") then
        RequestNamedPtfxAsset("core")
        while not HasNamedPtfxAssetLoaded("core") do
            Wait(1)
        end
    end
    UseParticleFxAssetNextCall("core")
    return StartParticleFxLoopedOnEntity('ent_sht_steam', vehicle, xOffset, yOffset, zOffset, xRot, yRot, zRot, scale, false, false, false)
end

function CreateVehicleExhaustBackfire(vehicle, scale)
    local exhaustNames = {
      "exhaust",    "exhaust_2",  "exhaust_3",  "exhaust_4",
      "exhaust_5",  "exhaust_6",  "exhaust_7",  "exhaust_8",
      "exhaust_9",  "exhaust_10", "exhaust_11", "exhaust_12",
      "exhaust_13", "exhaust_14", "exhaust_15", "exhaust_16"
    }
  
    for _, exhaustName in ipairs(exhaustNames) do
      local boneIndex = GetEntityBoneIndexByName(vehicle, exhaustName)
  
      if boneIndex ~= -1 then
        local pos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
        local off = GetOffsetFromEntityGivenWorldCoords(vehicle, pos.x, pos.y, pos.z)

        UseParticleFxAssetNextCall('core')
        if not HasNamedPtfxAssetLoaded("core") then
            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do
                Wait(1)
            end
        end
        SetPtfxAssetNextCall("core")

        --UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedOnEntity('veh_backfire', vehicle, off.x, off.y, off.z, 0.0, 0.0, 0.0, scale, false, false, false)
      end
    end
  end
  