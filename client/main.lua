local Core = exports.vorp_core:GetCore()

-- Prompts
local OpenShops, OpenCall, OpenReturn
local ShopGroup = GetRandomIntInRange(0, 0xffffff)

local KeepTame, SellTame
local TameGroup = GetRandomIntInRange(0, 0xffffff)

local TradeHorse
local TradeGroup = GetRandomIntInRange(0, 0xffffff)

local LootHorse
local LootGroup = GetRandomIntInRange(0, 0xffffff)

-- Target Prompts
local HorseDrink, HorseRest, HorseSleep, HorseWallow = 0, 0, 0, 0

-- Horse Tack
local BedrollsUsing, MasksUsing, MustachesUsing, HolstersUsing = nil, nil, nil, nil
local SaddlesUsing, SaddleclothsUsing, StirrupsUsing, HorseshoesUsing = nil, nil, nil, nil
local BagsUsing, ManesUsing, TailsUsing, SaddleHornsUsing, BridlesUsing = nil, nil, nil, nil, nil

-- Horse Training
local LastLoc, TamedModel = nil, nil
local IsTrainer, IsNaming, MaxBonding, HorseBreed = false, false, false, false

-- Misc.
MyHorse = 0
MyModel, MyHorseBreed, MyHorseColor = nil, nil, nil
local ShopEntity, MyEntity = 0, 0
local StableName, Site
local MyEntityID, MyHorseId
local InMenu, HasJob, UsingLantern, PromptsStarted, IsFleeing = false, false, false, false, false
local Drinking, Spawning, Sending, Cam, InWrithe, Activated = false, false, false, false, false, false
local DevModeActive = Config.devMode

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        SetTextCentre(1)
        DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x, _y)
    end
end

-- ฟังก์ชันคำนวณเลเวลความผูกพัน (Bonding Level) จาก XP
local function GetBondingLevel(xp)
    if xp >= 2400 then return 4
    elseif xp >= 1700 then return 3
    elseif xp >= 900 then return 2
    else return 1 end
end

function DebugPrint(message)
    if DevModeActive then
        print('^1[DEV MODE] ^4' .. message)
    end
end

local function isShopClosed(shopCfg)
    local hour = GetClockHours()
    local hoursActive = shopCfg.shop.hours.active

    if not hoursActive then
        return false
    end

    local openHour = shopCfg.shop.hours.open
    local closeHour = shopCfg.shop.hours.close

    if openHour < closeHour then
        -- Normal: shop opens and closes on the same day
        return hour < openHour or hour >= closeHour
    else
        -- Overnight: shop closes on the next day
        return hour < openHour and hour >= closeHour
    end
end

local function ManageStableBlip(site, closed)
    local siteCfg = Stables[site]

    if (closed and not siteCfg.blip.showClosed) or (not siteCfg.blip.show) then
        if siteCfg.Blip then
            RemoveBlip(siteCfg.Blip)
            siteCfg.Blip = nil
        end
        return
    end

    if not siteCfg.Blip then
        siteCfg.Blip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300, siteCfg.npc.coords) -- BlipAddForCoords
        SetBlipSprite(siteCfg.Blip, siteCfg.blip.sprite, true)
        Citizen.InvokeNative(0x9CB1A1623062F402, siteCfg.Blip, siteCfg.blip.name) -- SetBlipName
    end

    local color = siteCfg.blip.color.open
    if siteCfg.shop.jobsEnabled then color = siteCfg.blip.color.job end
    if closed then color = siteCfg.blip.color.closed end

    if Config.BlipColors[color] then
        Citizen.InvokeNative(0x662D364ABF16DE2F, siteCfg.Blip, joaat(Config.BlipColors[color])) -- BlipAddModifier
    else
        print('Error: Blip color not defined for color: ' .. tostring(color))
    end
end

local function AddStableNPC(site)
    local siteCfg = Stables[site]

    if not siteCfg.NPC then
        local modelName = siteCfg.npc.model
        local model = joaat(modelName)
        LoadModel(model, modelName)

        siteCfg.NPC = CreatePed(model, siteCfg.npc.coords.x, siteCfg.npc.coords.y, siteCfg.npc.coords.z - 1.0, siteCfg.npc.heading, false, true, true, true)
        Citizen.InvokeNative(0x283978A15512B2FE, siteCfg.NPC, true) -- SetRandomOutfitVariation

        TaskStartScenarioInPlace(siteCfg.NPC, `WORLD_HUMAN_WRITE_NOTEBOOK`, -1, true)
        SetEntityCanBeDamaged(siteCfg.NPC, false)
        SetEntityInvincible(siteCfg.NPC, true)
        Wait(500)
        FreezeEntityPosition(siteCfg.NPC, true)
        SetBlockingOfNonTemporaryEvents(siteCfg.NPC, true)
    end
end

local function RemoveStableNPC(site)
    local siteCfg = Stables[site]

    if siteCfg.NPC then
        DeleteEntity(siteCfg.NPC)
        siteCfg.NPC = nil
    end
end

local function RemoveHorsePrompts()
    local player = PlayerId()
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 35, 1, true) -- Hide TARGET_INFO
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 33, 1, true) -- Hide HORSE_FLEE
    UiPromptDelete(HorseDrink)
    UiPromptDelete(HorseRest)
    UiPromptDelete(HorseSleep)
    UiPromptDelete(HorseWallow)
    PromptsStarted = false
end

CreateThread(function()
    StartPrompts()

    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000

        if InMenu or IsEntityDead(playerPed) then goto END end

        for site, siteCfg in pairs(Stables) do
            local distance = #(playerCoords - siteCfg.npc.coords)
            local isClosed = isShopClosed(siteCfg)

            if siteCfg.blip.show then
                ManageStableBlip(site, isClosed)
            end

            -- 1. ส่วนจัดการ NPC (ห้ามลบโค้ดชุดนี้ ไม่งั้น NPC หาย)
            if distance > siteCfg.npc.distance or isClosed then
                RemoveStableNPC(site)
            elseif siteCfg.npc.active then
                AddStableNPC(site)
            end

            -- [เพิ่มใหม่] แสดงชื่อร้าน 3D บนหัว NPC (เมื่ออยู่ใกล้ระยะ 10 เมตร)
            if not isClosed and siteCfg.NPC and DoesEntityExist(siteCfg.NPC) and distance < 15.0 then
                -- เลือกแสดงชื่อร้าน (siteCfg.shop.name) หรือ ข้อความ Prompt (siteCfg.shop.prompt)
                local text = siteCfg.shop.name 
                DrawText3D(siteCfg.npc.coords.x, siteCfg.npc.coords.y, siteCfg.npc.coords.z + 1.2, text)
            end

            -- 2. ส่วนจัดการปุ่มกด UiPrompt (โค้ดเดิม)
            if distance <= siteCfg.shop.distance then
                sleep = 0

                -- ซ่อนปุ่ม Call/Return ตามที่คุณเคยขอ
                UiPromptSetVisible(OpenCall, false)
                UiPromptSetEnabled(OpenCall, false)
                UiPromptSetVisible(OpenReturn, false)
                UiPromptSetEnabled(OpenReturn, false)

                if isClosed then
                    local promptText = string.format("%s%s%s%s%s%s", siteCfg.shop.name, _U('hours'), siteCfg.shop.hours.open, _U('to'), siteCfg.shop.hours.close, _U('hundred'))
                    UiPromptSetActiveGroupThisFrame(ShopGroup, CreateVarString(10, 'LITERAL_STRING', promptText), 2, 0, 0, 0)
                    UiPromptSetEnabled(OpenShops, false)
                else
                    -- แสดงปุ่มกดปกติ
                    UiPromptSetActiveGroupThisFrame(ShopGroup, CreateVarString(10, 'LITERAL_STRING', siteCfg.shop.prompt), 2, 0, 0, 0)
                    UiPromptSetEnabled(OpenShops, true)

                    if UiPromptHasStandardModeCompleted(OpenShops, 0) then
                        if siteCfg.shop.jobsEnabled then
                            CheckPlayerJob(false, site)
                            if not HasJob then goto CONTINUE_LOOP end
                        end
                        OpenDashboard(site) -- <--- เปลี่ยนมาเรียกฟังก์ชันใหม่
                    end
                end
                
                ::CONTINUE_LOOP::
            end
        end
        ::END::
        Wait(sleep)
    end
end)

function OpenStable(site)
    CheckPlayerJob(false, site)
    DisplayRadar(false)
    InMenu = true
    Site = site
    StableName = Stables[Site].shop.name
    CreateCamera()

    local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
    if horseData then
        SendNUIMessage({
            action = 'show',
            shopData = JobMatchedHorses,
            compData = HorseComp,
            translations = Translations,
            location = StableName,
            currencyType = Config.currencyType,
            myHorsesData = horseData
        })
        SetNuiFocus(true, true)
    else
        print('No horse data received!')
    end
end

local function ClearShopHorse()
    if ShopEntity ~= 0 then
        DeleteEntity(ShopEntity)
        ShopEntity = 0
    end

    if MyEntity ~=0 then
        DeleteEntity(MyEntity)
        MyEntity = 0
    end
end

local function CheckEntityExists(entity)
    local timeout = 10000
    local startTime = GetGameTimer()

    while not DoesEntityExist(entity) do
        if GetGameTimer() - startTime > timeout then
            print('Failed to create entity:', entity)
            return false
        end
        Wait(10)
    end
    return true
end

-- View Horses for Purchase
RegisterNUICallback('loadHorse', function(data, cb)
    cb('ok')
    ClearShopHorse() -- ลบม้าตัวเก่าออกก่อนเสมอ
    
    -- [แก้ไข] เช็คว่าถ้าส่งมาเป็น 'CLEAR' ให้จบการทำงานเลย (แค่ลบ ไม่ต้องโหลดใหม่)
    if data.horseModel == 'CLEAR' then
        return
    end

    local modelName = data.horseModel
    local model = joaat(modelName)
    LoadModel(model, modelName)

    local siteCfg = Stables[Site]
    local coords = siteCfg.horse.coords
    ShopEntity = CreatePed(model, coords.x, coords.y, coords.z - 1.0, siteCfg.horse.heading, false, false, false, false)

    local entityExists = CheckEntityExists(ShopEntity)
    if not entityExists then
        return
    end

    Citizen.InvokeNative(0x283978A15512B2FE, ShopEntity, true) -- SetRandomOutfitVariation
    Citizen.InvokeNative(0x58A850EAEE20FAA3, ShopEntity) -- PlaceObjectOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, ShopEntity, true) -- FreezeEntityPosition

    if not Cam then
        Cam = true
        CameraLighting()
    end

    SetBlockingOfNonTemporaryEvents(ShopEntity, true)
    SetPedConfigFlag(ShopEntity, 113, true) -- DisableShockingEvents
    Wait(300)
    Citizen.InvokeNative(0x6585D955A68452A5, ShopEntity) -- ClearPedEnvDirt
end)

RegisterNUICallback('BuyHorse', function(data, cb)
    cb('ok')
    CheckPlayerJob(true, nil)

    if Stables[Site].trainerBuy and not IsTrainer then
        Core.NotifyRightTip(_U('trainerBuyHorse'), 4000)
        return
    end

    data.isTrainer = IsTrainer
    data.origin = 'buyHorse'
    
    -- [แก้ไข] รับชื่อม้าจาก NUI โดยตรง (ไม่ต้องใช้ SetHorseName)
    -- ถ้า NUI ส่ง data.name มาแล้ว ก็ใช้ได้เลย
    
    if data.name and data.name ~= "" then
        data.captured = 0
        local horseSaved = Core.Callback.TriggerAwait('bcc-stables:SaveNewHorse', data)
        if horseSaved then
            Core.NotifyRightTip("Horse Purchased!", 4000)
            -- รีเฟรชหน้าจอ (ถ้าต้องการ) หรือปิดเมนูไปเลย
        else
            -- ซื้อไม่สำเร็จ (เงินไม่พอ)
             Core.NotifyRightTip("Purchase Failed", 4000)
        end
    else
        -- ถ้าไม่มีชื่อส่งมา (เผื่อพลาด)
        Core.NotifyRightTip("Please enter a name", 4000)
    end
end)

function SetHorseName(data)
    IsNaming = true

    if data.origin ~= 'tameHorse' then
        SendNUIMessage({ action = 'hide' })
        SetNuiFocus(false, false)
        Wait(200)
    end

    AddTextEntry('FMMC_MPM_NA', _U('nameHorse'))
    DisplayOnscreenKeyboard(1, 'FMMC_MPM_NA', '', '', '', '', '', 30)

    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end

    if GetOnscreenKeyboardResult() then
        local horseName = GetOnscreenKeyboardResult()
        if string.len(horseName) > 0 then
            data.name = horseName
            if data.origin == 'updateHorse' then
                local nameSaved = Core.Callback.TriggerAwait('bcc-stables:UpdateHorseName', data)
                if nameSaved then
                    StableMenu()
                end
                IsNaming = false
                return
            elseif data.origin == 'buyHorse' then
                data.captured = 0
                local horseSaved = Core.Callback.TriggerAwait('bcc-stables:SaveNewHorse', data)
                if horseSaved then
                    StableMenu()
                end
                IsNaming = false
                return
            elseif data.origin == 'tameHorse' then
                data.captured = 1
                local playerPed = PlayerPedId()
                Citizen.InvokeNative(0x48E92D3DDE23C23A, playerPed, 0, 0, 0, 0, data.mount) -- TaskDismountAnimal
                while not Citizen.InvokeNative(0x01FEE67DB37F59B2, playerPed) do -- IsPedOnFoot
                    Wait(10)
                end
                local horseSaved = Core.Callback.TriggerAwait('bcc-stables:SaveTamedHorse', data)
                if horseSaved then
                    DeleteEntity(data.mount)
                    HorseBreed = false
                end
                IsNaming = false
                return
            end
        else
            SetHorseName(data)
            return
        end
    end

    if data.origin ~= 'tameHorse' then
        local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        if horseData then
            SendNUIMessage({
                action = 'show',
                shopData = JobMatchedHorses,
                compData = HorseComp,
                translations = Translations,
                location = StableName,
                currencyType = Config.currencyType,
                myHorsesData = horseData
            })
            SetNuiFocus(true, true)
        end
    end
    IsNaming = false
end

RegisterNUICallback('RenameHorse', function(data, cb)
    cb('ok')
    data.origin = 'updateHorse'
    SetHorseName(data)
end)

RegisterNUICallback('loadMyHorse', function(data, cb)
    cb('ok')
    ClearShopHorse()
    MyEntityID = data.HorseId
    local components = json.decode(data.HorseComp)

    -- [สำคัญ] รีเซ็ตตัวแปรมารอก่อน
    SaddlesUsing = nil; SaddleclothsUsing = nil; StirrupsUsing = nil; BagsUsing = nil;
    ManesUsing = nil; TailsUsing = nil; SaddleHornsUsing = nil; BedrollsUsing = nil;
    MasksUsing = nil; MustachesUsing = nil; HolstersUsing = nil; BridlesUsing = nil; HorseshoesUsing = nil;

    local modelName = data.HorseModel
    local model = joaat(modelName)
    LoadModel(model, modelName)

    local siteCfg = Stables[Site]
    local coords = siteCfg.horse.coords
    MyEntity = CreatePed(model, coords.x, coords.y, coords.z - 1.0, siteCfg.horse.heading, false, false, false, false)

    -- ... (โค้ดสร้างม้าอื่นๆ ของคุณ ข้ามไปส่วนท้าย function) ...
    Citizen.InvokeNative(0x283978A15512B2FE, MyEntity, true)
    Citizen.InvokeNative(0x58A850EAEE20FAA3, MyEntity)
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, MyEntity, true)
    
    if not Cam then Cam = true; CameraLighting() end
    SetBlockingOfNonTemporaryEvents(MyEntity, true)
    SetPedConfigFlag(MyEntity, 113, true)
    Citizen.InvokeNative(0x6585D955A68452A5, MyEntity)

    -- [ส่วนสำคัญที่สุด] โหลดของเดิมเข้าตัวแปร
    if components and components ~= '[]' then
        for _, component in ipairs(components) do
            local compHash = tonumber(component)
            SetComponent(MyEntity, compHash) -- ใส่ให้ม้าตัวอย่าง

            -- Map เข้าตัวแปร Global เพื่อให้ SaveComps รู้จัก
            for category, items in pairs(HorseComp) do
                for _, item in ipairs(items) do
                    if tonumber(item.hash) == compHash then
                        if category == 'Saddles' then SaddlesUsing = compHash
                        elseif category == 'Saddlecloths' then SaddleclothsUsing = compHash
                        elseif category == 'Stirrups' then StirrupsUsing = compHash
                        elseif category == 'SaddleBags' then BagsUsing = compHash
                        elseif category == 'Manes' then ManesUsing = compHash
                        elseif category == 'Tails' then TailsUsing = compHash
                        elseif category == 'SaddleHorns' then SaddleHornsUsing = compHash
                        elseif category == 'Bedrolls' then BedrollsUsing = compHash
                        elseif category == 'Masks' then MasksUsing = compHash
                        elseif category == 'Mustaches' then MustachesUsing = compHash
                        elseif category == 'Holsters' then HolstersUsing = compHash
                        elseif category == 'Bridles' then BridlesUsing = compHash
                        elseif category == 'Horseshoes' then HorseshoesUsing = compHash
                        end
                        break -- เจอแล้วหยุด loop นี้
                    end
                end
            end
        end
    end
end)

RegisterNUICallback('selectHorse', function(data, cb)
    cb('ok')
    TriggerServerEvent('bcc-stables:SelectHorse', data)
end)

function GetSelectedHorse()
    local data = Core.Callback.TriggerAwait('bcc-stables:GetHorseData')

    if data == false then
        return print('No selected-horse data returned!')
    end

    -- เพิ่มการตรวจสอบสถานะตาย
    if data.dead == 1 then
        -- ตรวจสอบว่าผู้เล่นอยู่ใกล้คอกม้าหรือไม่ (เช็คจากตัวแปร InMenu หรือ ShopGroup)
        -- แต่เพื่อให้ง่าย เราจะเช็คว่าถ้ากดเรียกในขณะที่ Prompt "Call Horse" ของร้านค้าทำงานอยู่
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local nearStable = false
        
        for site, siteCfg in pairs(Stables) do
            if #(coords - siteCfg.npc.coords) <= siteCfg.shop.distance then
                nearStable = true
                break
            end
        end

        if nearStable then
            -- ถ้าอยู่หน้าคอกม้า ให้ทำการรักษา
            local revived = Core.Callback.TriggerAwait('bcc-stables:ReviveAtStable')
            if revived then
                Core.NotifyRightTip("Revive Horse", 4000)
                -- เรียกฟังก์ชันนี้อีกครั้งเพื่อเสกม้าออกมา
                GetSelectedHorse() 
            else
                Core.NotifyRightTip("Money not enough", 4000)
            end
        else
            -- ถ้าอยู่นอกพื้นที่คอกม้า แจ้งเตือนว่าตาย
            Core.NotifyRightTip("Horse Dead", 4000)
            -- หรือใช้ TriggerEvent("vorp:TipBottom", "ม้าของคุณเสียชีวิตแล้ว", 4000)
        end
        return -- จบการทำงาน ไม่เสกม้า
    end

    SpawnHorse(data)
end

RegisterNUICallback('CloseStable', function(data, cb)
    cb('ok')

    SendNUIMessage({ action = 'hide' })
    SetNuiFocus(false, false)

    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Leaderboard_Hide', 'MP_Leaderboard_Sounds', true, 0) 

    ClearShopHorse()

    Cam = false
    DestroyAllCams(true)
    DisplayRadar(true)
    InMenu = false
    ClearPedTasksImmediately(PlayerPedId())

    if data.MenuAction == 'save' then
        -- 1. ตรวจสอบและหักเงิน (ใช้ Server Callback เดิม)
        local result = Core.Callback.TriggerAwait('bcc-stables:BuyTack', data)
        
        -- 2. ถ้าหักเงินสำเร็จ ให้บันทึกด้วย Logic เดิม (SaveComps)
        -- ฟังก์ชัน SaveComps() จะไปรวบรวมตัวแปร global (เช่น SaddlesUsing) ที่ถูกจำค่าไว้ตอน loadMyHorse หรือตอนเลือกของ แล้วบันทึกลง Database
        if result then
            SaveComps()
        end
    end
end)

function SaveComps()
    -- ใช้ CreateThread เพื่อแยกการทำงานไปอยู่เบื้องหลัง ไม่ให้ขวางการทำงานหลัก (แก้ปัญหาจอกระตุก)
    CreateThread(function()
        -- สร้างตารางเก็บข้อมูลอุปกรณ์
        local compData = {}

        local function addComp(value)
            if value and tonumber(value) and tonumber(value) ~= 0 then
                table.insert(compData, tonumber(value))
            end
        end

        -- รวบรวมรายการอุปกรณ์
        addComp(SaddlesUsing)
        addComp(SaddleclothsUsing)
        addComp(StirrupsUsing)
        addComp(BagsUsing)
        addComp(ManesUsing)
        addComp(TailsUsing)
        addComp(SaddleHornsUsing)
        addComp(BedrollsUsing)
        addComp(MasksUsing)
        addComp(MustachesUsing)
        addComp(HolstersUsing)
        addComp(BridlesUsing)
        addComp(HorseshoesUsing)

        local compDataEncoded = json.encode(compData)

        if compDataEncoded then
            -- 1. บันทึกลง Database (TriggerAwait จะรอ Server ตอบกลับ แต่เมื่ออยู่ใน Thread จะไม่ทำให้จอกระตุก)
            local result = Core.Callback.TriggerAwait('bcc-stables:UpdateComponents', compDataEncoded, MyEntityID)
            
            if result then
                -- 2. อัปเดตม้าตัวอย่างในร้าน (Shop Horse)
                if MyEntity ~= 0 then
                    local categoriesToRemove = {
                        0xBAA7E618, 0x17CEB41A, 0xDA6DADCA, 0x80451C25, 
                        0xAA0217AB, 0x5447332, 0xEFB31921, 0xD3500E5D, 
                        0x30DEFDDF, 0xAC106B30, 0x94B2E3AF, 0xFACFC3C0
                    }
                    for _, cat in ipairs(categoriesToRemove) do
                        Citizen.InvokeNative(0xD710A5007C2AC539, MyEntity, cat, 0) 
                    end
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyEntity, false, true, true, true, false)

                    for _, component in ipairs(compData) do
                        SetComponent(MyEntity, component)
                    end
                end

                -- 3. อัปเดตม้าจริง (Real Horse)
                local realHorseID = tonumber(MyHorseId)
                local shopHorseID = tonumber(MyEntityID)

                if MyHorse ~= 0 and realHorseID == shopHorseID then
                    local categoriesToRemove = {
                        0xBAA7E618, 0x17CEB41A, 0xDA6DADCA, 0x80451C25, 
                        0xAA0217AB, 0x5447332, 0xEFB31921, 0xD3500E5D, 
                        0x30DEFDDF, 0xAC106B30, 0x94B2E3AF, 0xFACFC3C0
                    }
                    
                    for _, cat in ipairs(categoriesToRemove) do
                        Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse, cat, 0)
                    end
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)

                    for _, component in ipairs(compData) do
                        SetComponent(MyHorse, component)
                    end
                    
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)
                    print("^2[BCC-Stables] Real horse updated successfully!^0")
                end
            end
        end
    end)
end

-- Reopen Menu After Sell or Failed Purchase
function StableMenu()
    ClearShopHorse()

    local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        if horseData then
            SendNUIMessage({
            action = 'show',
            shopData = JobMatchedHorses,
            compData = HorseComp,
            translations = Translations,
            location = StableName,
            currencyType = Config.currencyType,
            myHorsesData = horseData
        })
        SetNuiFocus(true, true)
    end
end

function SpawnHorse(data)
    if Spawning then
        return
    end
    Spawning = true

    if MyHorse ~= 0 then
        DeleteEntity(MyHorse)
        MyHorse = 0
    end

    MyHorseId = data.id
    HorseName = data.name
    local xp = data.xp
    local components = json.decode(data.components)

    local horseModel = data.model
    MyModel = joaat(horseModel)
    LoadModel(MyModel, horseModel)

    -- ค้นหา Breed และ Color
    for _, horseCfg in pairs(Horses) do
        for model, modelCfg in pairs(horseCfg.colors) do
            local horseHash = joaat(model)
            if horseHash == MyModel then
                MyHorseBreed = horseCfg.breed
                MyHorseColor = modelCfg.color
                break
            end
        end
    end

    local player = PlayerId()
    local playerPed = PlayerPedId()
    local x, y, z = table.unpack(GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -10.0, 0.0))
    local spawnPosition = nil
    for height = 1, 1000 do
        local groundCheck, ground = GetGroundZAndNormalFor_3dCoord(x, y, height + 0.0)
        if groundCheck then
            spawnPosition = vector3(x, y, ground)
            break
        end
    end

    local index = 0
    while index < 25 do
        local nodeCheck, node = GetNthClosestVehicleNode(x, y, z, index, 1, 1077936128, 0)
        if nodeCheck then
            spawnPosition = node
            break
        else
            index = index + 3
        end
    end

    if not spawnPosition then
        Spawning = false -- Reset state if failed
        return print('No spawn position found!')
    end

    MyHorse = CreatePed(MyModel, spawnPosition.x, spawnPosition.y, spawnPosition.z, GetEntityHeading(playerPed), true, false, false, false)
    local entityExists = CheckEntityExists(MyHorse)
    if not entityExists then
        Spawning = false
        return
    end

    ---------------------------------------------------------------------------
    -- [ส่วนสำคัญ] ตั้งค่า Stats (SetAttributeBaseRank)
    ---------------------------------------------------------------------------
    if Config.HorseStats and Config.HorseStats[MyHorseBreed] then
        local stats = Config.HorseStats[MyHorseBreed]
        print("^2[BCC-Debug] Applying Stats for Breed: " .. tostring(MyHorseBreed) .. "^0") -- เช็คตรงนี้ใน F8

        -- 0: PA_HEALTH (เลือด)
        if stats.health then
            Citizen.InvokeNative(0x5DA12E025D47D4E5, MyHorse, 0, math.floor(stats.health))
            Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, 100) 
        end

        -- 1: PA_STAMINA (ความอึด)
        if stats.stamina then
            Citizen.InvokeNative(0x5DA12E025D47D4E5, MyHorse, 1, math.floor(stats.stamina))
            Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, 100)
        end

        -- 3: PA_COURAGE (ความกล้า)
        if stats.courage then
            Citizen.InvokeNative(0x5DA12E025D47D4E5, MyHorse, 3, math.floor(stats.courage))
        end

        -- 4: PA_AGILITY (การเลี้ยว)
        if stats.agility then
            Citizen.InvokeNative(0x5DA12E025D47D4E5, MyHorse, 4, math.floor(stats.agility))
        end

        -- 5: PA_SPEED (ความเร็ว)
        if stats.speed then
            Citizen.InvokeNative(0x5DA12E025D47D4E5, MyHorse, 5, math.floor(stats.speed))
            print("   - Set Speed Rank: " .. stats.speed)
        end

        -- 6: PA_ACCELERATION (อัตราเร่ง)
        if stats.acceleration then
            Citizen.InvokeNative(0x5DA12E025D47D4E5, MyHorse, 6, math.floor(stats.acceleration))
            print("   - Set Accel Rank: " .. stats.acceleration)
        end
    else
        print("^1[BCC-Debug] No stats config found for: " .. tostring(MyHorseBreed) .. "^0")
    end
    ---------------------------------------------------------------------------

    SetModelAsNoLongerNeeded(MyModel)

    LocalPlayer.state.HorseData = {
        MyHorse = NetworkGetNetworkIdFromEntity(MyHorse)
    }

    Citizen.InvokeNative(0x9587913B9E772D29, MyHorse, 0) -- PlaceEntityOnGroundProperly
    Citizen.InvokeNative(0x283978A15512B2FE, MyHorse, true) -- SetRandomOutfitVariation
    if data.gender == 'female' then
        Citizen.InvokeNative(0x5653AB26C82938CF, MyHorse, 41611, 1.0) -- SetCharExpression
        Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false) -- UpdatePedVariation
    end
    Citizen.InvokeNative(0xD2CB0FB0FDCB473D, playerPed, MyHorse) -- SetPedAsSaddleHorseForPlayer
    Citizen.InvokeNative(0x931B241409216C1F, playerPed, MyHorse, false) -- SetPedOwnsAnimal
    Citizen.InvokeNative(0xB8B6430EAD2D2437, MyHorse, `PLAYER_HORSE`) -- SetPedPersonality
    Citizen.InvokeNative(0xE6D4E435B56D5BD0, player, MyHorse) -- SetPlayerOwnsMount

    -- Horse Prompts
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 49, 1, true) -- HORSE_BRUSH
    Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 50, 1, true) -- HORSE_FEED
    if not Config.fleeEnabled then
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 33, 1, true) -- HORSE_FLEE
    end

    -- Set Initial Health/Stamina Core
    local health = data.health or 100
    if health == 0 then health = 100 end
    Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, health)

    local stamina = data.stamina or 100
    if stamina == 0 then stamina = 100 end
    Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, stamina)

    -- Bonding
    Citizen.InvokeNative(0x09A59688C26D88DF, MyHorse, 7, xp)
    local maxXp = Citizen.InvokeNative(0x223BF310F854871C, MyHorse, 7)
    MaxBonding = (xp >= maxXp)

    if Config.trainerOnly then
        CheckPlayerJob(true, nil)
        if IsTrainer then TriggerEvent('bcc-stables:HorseBonding') end
    else
        TriggerEvent('bcc-stables:HorseBonding')
    end

    local currentLevel = Citizen.InvokeNative(0x147149F2E909323C, MyHorse, 7, Citizen.ResultAsInteger())

    if currentLevel >= 2 then Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 113, true) end
    if currentLevel >= 3 then Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 312, true) end
    Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 297, true)
    Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 471, Config.disableKick)
    Citizen.InvokeNative(0xE2487779957FE897, MyHorse, 528)

    local horseBlip = Citizen.InvokeNative(0x23f74c2fda6e7c61, -1230993421, MyHorse)
    Citizen.InvokeNative(0x9CB1A1623062F402, horseBlip, HorseName)
    SetPedPromptName(MyHorse, HorseName)

    TriggerServerEvent('bcc-stables:RegisterInventory', MyHorseId, horseModel)

    if Config.shareInventory then
        Entity(MyHorse).state:set('myHorseId', MyHorseId, true)
    end

    if Config.horseTag then TriggerEvent('bcc-stables:HorseTag') end

    TriggerEvent('bcc-stables:TradeHorse')
    PromptsStarted = false
    TriggerEvent('bcc-stables:HorsePrompts')

    if Config.saveInterval > 0 then TriggerEvent('bcc-stables:HorseMonitor') end

    if components and components ~= '[]' then
        for _, component in ipairs(components) do SetComponent(MyHorse, component) end
    end

    InWrithe = false
    Activated = false
    LastLoc = nil
    UsingLantern = false
    Spawning = false

    if data.writhe == 1 then
        TriggerEvent('bcc-stables:ManageHorseDeath')
        return
    end

    Sending = true
    SendHorse()
end

-- Loot Players Horse Inventory
CreateThread(function()
    if Config.shareInventory then
        while true do
            local horse, horseId, isLeading, owner = nil, nil, nil, nil
            local playerPed = PlayerPedId()
            local sleep = 1000

            if (IsEntityDead(playerPed)) or (not IsPedOnFoot(playerPed)) then goto END end

            horse = Citizen.InvokeNative(0x0501D52D24EA8934, 1, Citizen.ResultAsInteger()) -- Get HorsePedId in Range
            if (horse == 0) or (horse == MyHorse) then goto END end

            owner = Citizen.InvokeNative(0xAD03B03737CE6810, horse) -- GetPlayerOwnerOfMount
            isLeading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, playerPed) -- IsPedLeadingHorse
            if (owner == 255) or isLeading then goto END end

            sleep = 0
            UiPromptSetActiveGroupThisFrame(LootGroup, CreateVarString(10, 'LITERAL_STRING', _U('lootInventory')), 1, 0, 0, 0)
            if UiPromptHasStandardModeCompleted(LootHorse, 0) then
                horseId = Entity(horse).state.myHorseId
                OpenInventory(horse, horseId, true)
            end
            ::END::
            Wait(sleep)
        end
    end
end)

-- Set Horse Name and Health Bar Above Horse
AddEventHandler('bcc-stables:HorseTag', function()
    local tagDistance = Config.tagDistance
    local gamerTagId = Citizen.InvokeNative(0xE961BF23EAB76B12, MyHorse, HorseName) -- CreateMpGamerTagOnEntity
    Citizen.InvokeNative(0x5F57522BC1EB9D9D, gamerTagId, `PLAYER_HORSE`) -- SetMpGamerTagTopIcon

    while MyHorse ~= 0 do
        Wait(1000)

        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(MyHorse))
        if dist < tagDistance and Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
            Citizen.InvokeNative(0x93171DDDAB274EB8, gamerTagId, 3) -- SetMpGamerTagVisibility
        else
            if Citizen.InvokeNative(0x502E1591A504F843, gamerTagId, MyHorse) then -- IsMpGamerTagActiveOnEntity
                Citizen.InvokeNative(0x93171DDDAB274EB8, gamerTagId, 0) -- SetMpGamerTagVisibility
            end
        end
    end

    Citizen.InvokeNative(0x839BFD7D7E49FE09, Citizen.PointerValueIntInitialized(gamerTagId)) -- RemoveMpGamerTag
end)

-- Manage Horse Lockon Prompts
local function HandleHorseAction(key, action)
    if Citizen.InvokeNative(0x580417101DDB492F, 0, key) and not Drinking then
        action()
    end
end

AddEventHandler('bcc-stables:HorsePrompts', function()
    local player = PlayerId()
    local fleeEnabled = Config.fleeEnabled
    local distanceCheckEnabled = Config.horseDistance.enabled
    local horseRadius = Config.horseDistance.radius
    local drinkKey = Config.keys.drink
    local restKey = Config.keys.rest
    local sleepKey = Config.keys.sleep
    local wallowKey = Config.keys.wallow

    while MyHorse ~= 0 do
        local playerPed = PlayerPedId()
        local sleep = 1000
        local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

        if distanceCheckEnabled and distance > horseRadius then
            SaveHorseStats(InWrithe)
            DeleteEntity(MyHorse)
            MyHorse = 0
            goto END
        end

        if (IsPlayerFreeAiming(player)) or (distance > 2.8) or (IsEntityDead(playerPed)) then
            RemoveHorsePrompts()
            goto END
        end

        sleep = 0

        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, `INPUT_OPEN_SATCHEL_HORSE_MENU`) then -- IsDisabledControlJustPressed
            OpenInventory(MyHorse, MyHorseId, false)
        end

        if InWrithe and Citizen.InvokeNative(0x91AEF906BCA88877, 0, `INPUT_REVIVE`) then  -- IsDisabledControlJustPressed
            TriggerEvent('bcc-stables:ReviveHorse')
            goto END
        end

        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 35, 1, false) -- Show TARGET_INFO
        Citizen.InvokeNative(0xA3DB37EDF9A74635, player, MyHorse, 33, 1, false) -- Show HORSE_FLEE

        if Citizen.InvokeNative(0x27F89FDC16688A7A, player, MyHorse, false) then -- IsPlayerTargettingEntity
            sleep = 0
            local menuGroup = Citizen.InvokeNative(0xB796970BD125FCE8, MyHorse) -- PromptGetGroupIdForTargetEntity
            HorseTargetPrompts(menuGroup)

            HandleHorseAction(drinkKey, HorseDrinking)
            HandleHorseAction(restKey, HorseResting)
            HandleHorseAction(sleepKey, HorseSleeping)
            HandleHorseAction(wallowKey, HorseWallowing)

            if fleeEnabled and Citizen.InvokeNative(0x580417101DDB492F, 0, `INPUT_HORSE_COMMAND_FLEE`) then -- IsControlJustPressed
                FleeHorse()
            end
        end
        ::END::
        Wait(sleep)
    end
end)

function HorseDrinking()
    if not IsEntityInWater(MyHorse) then
        Core.NotifyRightTip(HorseName .. _U('needWater'), 4000)
        return
    end

    Drinking = true
    local drinkTime = Config.drinkLength * 1000
    local dict = 'amb_creature_mammal@world_horse_drink_ground@idle'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'idle_a', 1.0, 1.0, drinkTime, 3, 1.0, false, false, false)
    end

    Wait(drinkTime)

    local health = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue

    if health < 100 or stamina < 100 then
        local healthBoost = Config.boost.drinkHealth
        local staminaBoost = Config.boost.drinkStamina

        if healthBoost > 0 then
            local newHealth = math.min(health + healthBoost, 100)
            Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, newHealth) -- SetAttributeCoreValue
        end

        if staminaBoost > 0 then
            local newStamina = math.min(stamina + staminaBoost, 100)
            Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, newStamina) -- SetAttributeCoreValue
        end

        if Config.horseXpPerDrink > 0 and not MaxBonding then
            if not Config.trainerOnly or (Config.trainerOnly and IsTrainer) then
                SaveXp('drink')
            end
        end

        Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
    end

    Drinking = false
end

function HorseResting()
    if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
        return
    end

    local dict = 'amb_creature_mammal@world_horse_resting@idle'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
    end
end

function HorseSleeping()
    if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
        return
    end

    local dict = 'amb_creature_mammal@world_horse_sleeping@base'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'base', 1.0, 1.0, -1, 3, 1.0, false, false, false)
    end
end

function HorseWallowing()
    if not Citizen.InvokeNative(0xAAB0FE202E9FC9F0, MyHorse, -1) then -- IsMountSeatFree
        return
    end

    local dict = 'amb_creature_mammal@world_horse_wallow_shake@idle'

    if LoadAnim(dict) then
        TaskPlayAnim(MyHorse, dict, 'idle_a', 1.0, 1.0, -1, 3, 1.0, false, false, false)
    end
end

function LoadAnim(dict)
    RequestAnimDict(dict)
    local startTime = GetGameTimer()
    local timeout = 5000

    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() - startTime > timeout then
            print("Failed to load animation dictionary " .. dict)
            return false
        end
        Wait(10)
    end
    return true
end

-- Event Listener
CreateThread(function()
    local writheEnabled = Config.death.writheEnabled
    while true do
        Wait(0)

        local size = GetNumberOfEvents(0)
        if size > 0 then
            for i = 0, size - 1 do
                local event = Citizen.InvokeNative(0xA85E614430EFF816, 0, i) -- GetEventAtIndex

                if event == 1327216456 then -- EVENT_PED_WHISTLE
                    local eventDataSize = 2
                    local eventDataStruct = DataView.ArrayBuffer(128)
                    eventDataStruct:SetInt32(0, 0) -- whistler ped id
                    eventDataStruct:SetInt32(8, 0) -- whistle type

                    local data = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    if data then
                        if eventDataStruct:GetInt32(0) == PlayerPedId() then
                            if eventDataStruct:GetInt32(8) ~= 869278708 then -- WHISTLEHORSELONG
                                TriggerEvent('bcc-stables:WhistleHorse')
                            else
                                TriggerEvent('bcc-stables:LongWhistleHorse')
                            end
                        end
                    end

                elseif event == 218595333 then -- EVENT_HORSE_BROKEN
                    local eventDataSize = 3
                    local eventDataStruct = DataView.ArrayBuffer(128)
                    eventDataStruct:SetInt32(0, 0)  -- Rider Ped Id
                    eventDataStruct:SetInt32(8, 0)  -- Horse Ped Id
                    eventDataStruct:SetInt32(16, 0) -- Broken Type Id

                    local data = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    if data then
                        if eventDataStruct:GetInt32(16) == 2 then -- Horse Taming Successful
                            local tamedPedId = eventDataStruct:GetInt32(8)
                            local tamedNetId = NetworkGetNetworkIdFromEntity(tamedPedId)
                            Entity(tamedPedId).state:set('netId', tamedNetId, true)
                        end
                    end

                elseif event == 2145012826 then -- EVENT_ENTITY_DESTROYED 
                    local eventDataSize = 9
                    local eventDataStruct = DataView.ArrayBuffer(128)
                    eventDataStruct:SetInt32(0, 0)  -- Destroyed Entity Id
                    eventDataStruct:SetInt32(8, 0)  -- Object/Ped Id that Damaged Entity
                    eventDataStruct:SetInt32(16, 0) -- Weapon Hash that Damaged Entity
                    eventDataStruct:SetInt32(24, 0) -- Ammo Hash that Damaged Entity
                    eventDataStruct:SetInt32(32, 0) -- (float) Damage Amount
                    eventDataStruct:SetInt32(40, 0) -- Unknown
                    eventDataStruct:SetInt32(48, 0) -- (float) Entity Coord x
                    eventDataStruct:SetInt32(56, 0) -- (float) Entity Coord y
                    eventDataStruct:SetInt32(64, 0) -- (float) Entity Coord z

                    local data = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, 0, i, eventDataStruct:Buffer(), eventDataSize) -- GetEventData
                    local entity = eventDataStruct:GetInt32(0)
                    if data then
                        if entity == MyHorse then
                            if writheEnabled then
                                TriggerEvent('bcc-stables:ManageHorseDeath')
                            else
                                Wait(5000)
                                SaveHorseStats(true)
                                DeleteEntity(MyHorse)
                                MyHorse = 0
                            end
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('bcc-stables:ManageHorseDeath', function()
    if not InWrithe then
        -- ส่วนของการเข้าสถานะบาดเจ็บ (Writhe) เหมือนเดิม
        InWrithe = true
        Citizen.InvokeNative(0x71BC8E838B9C6035, MyHorse) -- ResurrectPed
        Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 136, false)-- SetPedConfigFlag / CannotBeMounted
        Citizen.InvokeNative(0x8C038A39C4A4B6D6, MyHorse, 0, 0) -- TaskAnimalWrithe
        Wait(100)
        Citizen.InvokeNative(0x925A160133003AC6, MyHorse, true) -- SetPausePedWritheBleedout
        RemoveHorsePrompts()

        Core.NotifyRightTip(_U('horseWrithe'), 4000)

        if Config.death.persistentWrithe then
            TriggerServerEvent('bcc-stables:SetHorseWrithe', MyHorseId)
        end

        SaveHorseStats(true)
    else
        -- [แก้ไขส่วนนี้] เมื่อม้าตายสนิท (หลังจาก Writhe หรือถูกซ้ำ)
        local action = 'dead' -- บังคับให้เป็นสถานะตาย
        
        -- แจ้งเตือนว่าม้าเสียชีวิต
        Core.NotifyRightTip("Horse Dead", 4000) 
        
        -- อัปเดตสถานะลงฐานข้อมูล
        TriggerServerEvent('bcc-stables:UpdateHorseStatus', MyHorseId, action)

        Wait(5000)
        SaveHorseStats(true)
        DeleteEntity(MyHorse)
        MyHorse = 0
        InWrithe = false
    end
end)

-- Call Horse to Player
AddEventHandler('bcc-stables:WhistleHorse', function()
    if MyHorse == 0 then
        WhistleSpawn()
        return
    end

    if Citizen.InvokeNative(0x77F1BEB8863288D5, MyHorse, 0x4924437D, false) ~= 0 then -- GetScriptTaskStatus / SCRIPT_TASK_GO_TO_ENTITY
        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(MyHorse))

        if dist >= 100 then
            DeleteEntity(MyHorse)
            MyHorse = 0
            GetSelectedHorse()
        else
            Sending = true
            SendHorse()
        end
    end
end)

-- Call Horse or have Horse Follow Player
AddEventHandler('bcc-stables:LongWhistleHorse', function()
    local playerPed = PlayerPedId()

    if MyHorse == 0 then
        WhistleSpawn()
        return
    end

    if Citizen.InvokeNative(0x77F1BEB8863288D5, MyHorse, 0x4924437D, 0) ~= 0 then -- GetScriptTaskStatus
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

        if dist <= 45 then
            if Citizen.InvokeNative(0x77F1BEB8863288D5, MyHorse, 0x3EF867F4, 0) ~= 1 then -- GetScriptTaskStatus
                Citizen.InvokeNative(0x304AE42E357B8C7E, MyHorse, playerPed, math.random(1.0, 4.0), math.random(5.0, 8.0), 0.0, 0.7, -1, 3.0, true) -- TaskFollowToOffsetOfEntity
            else
                ClearPedTasks(MyHorse)
            end
        end
    end
end)

function WhistleSpawn()
    if Config.whistleSpawn then
        GetSelectedHorse()
    else
        Core.NotifyRightTip(_U('stableSpawn'), 4000)
    end
end

-- Move horse to Player
function SendHorse()
    local playerPed = PlayerPedId()

    TaskGoToEntity(MyHorse, playerPed, -1, 10.2, 2.0, 0.0, 0)

    while Sending do
        Wait(0)
        local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))
        if dist <= 10.0 then
            ClearPedTasks(MyHorse)
            Sending = false
        end
    end
end

-- Wild Horse Taming
CreateThread(function()
    local horseModel

    while true do
        local mount = Citizen.InvokeNative(0xE7E11B8DCBED1058, PlayerPedId()) -- GetMount
        if not mount or mount == MyHorse then
            goto END
        end

        horseModel = GetEntityModel(mount)

        for _, horseCfg in pairs(Horses) do
            for model, modelCfg in pairs(horseCfg.colors) do
                local horseHash = joaat(model)
                if horseHash == horseModel then
                    TamedModel = model
                    if Config.displayHorseBreed and not HorseBreed then
                        if horseCfg.breed == 'Other' then
                            Core.NotifyBottomRight(modelCfg.color, 1000)
                        else
                            Core.NotifyBottomRight(horseCfg.breed, 1000)
                        end
                        HorseBreed = true
                    end
                end
            end
        end
        ::END::
        Wait(1000)
    end
end)

CreateThread(function()
    local mount = 0
    local mountNetId, tamedNetId
    local allowSale = Config.allowSale
    local allowKeep = Config.allowKeep
    local trainerOnly = Config.trainerOnly

    while true do
        local playerPed = PlayerPedId()
        local sleep = 1000

        if IsEntityDead(playerPed) then goto END end

        mount = Citizen.InvokeNative(0xE7E11B8DCBED1058, playerPed) -- GetMount
        if mount and mount ~= 0 then
            mountNetId = NetworkGetNetworkIdFromEntity(mount)
            tamedNetId = Entity(mount).state.netId
        end

        for site, siteCfg in pairs(Trainers) do
            local distance = #(GetEntityCoords(playerPed) - siteCfg.npc.coords)

            if siteCfg.blip.show and not siteCfg.TrainerBlip then
                AddTrainerBlip(site)
                Citizen.InvokeNative(0x662D364ABF16DE2F, siteCfg.TrainerBlip, joaat(Config.BlipColors[siteCfg.blip.color])) -- BlipAddModifier
            end

            if siteCfg.npc.active then
                if distance <= siteCfg.npc.distance then
                    if not siteCfg.TrainerNPC then
                        AddTrainerNPC(site)
                    end
                elseif siteCfg.TrainerNPC then
                    DeleteEntity(siteCfg.TrainerNPC)
                    siteCfg.TrainerNPC = nil
                end
            end

            if (distance <= siteCfg.shop.distance) and (IsPedOnMount(playerPed)) and (mountNetId == tamedNetId) and (not IsNaming) then
                sleep = 0
                UiPromptSetActiveGroupThisFrame(TameGroup, CreateVarString(10, 'LITERAL_STRING', siteCfg.shop.prompt), 1, 0, 0, 0)

                UiPromptSetVisible(SellTame, allowSale)
                UiPromptSetEnabled(SellTame, allowSale)

                UiPromptSetVisible(KeepTame, allowKeep)
                UiPromptSetEnabled(KeepTame, allowKeep)

                if Citizen.InvokeNative(0xE0F65F0640EF0617, SellTame) then  -- PromptHasHoldModeCompleted
                    local onCooldown = Core.Callback.TriggerAwait('bcc-stables:CheckPlayerCooldown', 'sellTame')
                    if onCooldown then
                        Core.NotifyRightTip(_U('sellCooldown'), 4000)
                        HorseBreed = false
                        goto END
                    end

                    if trainerOnly then
                        CheckPlayerJob(true, nil)
                        if not IsTrainer then
                            Core.NotifyRightTip(_U('trainerSellHorse'), 4000)
                            HorseBreed = false
                            goto END
                        end
                    end

                    TriggerServerEvent('bcc-stables:SellTamedHorse', GetEntityModel(mount))

                    if mount ~= 0 then
                        Citizen.InvokeNative(0x48E92D3DDE23C23A, playerPed, 0, 0, 0, 0, mount) -- TaskDismountAnimal

                        while not Citizen.InvokeNative(0x01FEE67DB37F59B2, playerPed) do -- IsPedOnFoot
                            Wait(10)
                        end

                        Core.NotifyRightTip(_U('tamedCooldown') .. Config.cooldown.sellTame .. _U('minutes'), 4000)
                        DeleteEntity(mount)
                        mount = 0
                        Wait(200)
                        HorseBreed = false
                    end
                end

                if Citizen.InvokeNative(0xE0F65F0640EF0617, KeepTame) then  -- PromptHasHoldModeCompleted
                    CheckPlayerJob(true, nil)
                    if trainerOnly then
                        if not IsTrainer then
                            Core.NotifyRightTip(_U('trainerRegHorse'), 4000)
                            HorseBreed = false
                            goto END
                        end
                    end

                    local tameData = {
                        isTrainer = IsTrainer,
                        ModelH = TamedModel,
                        origin = 'tameHorse',
                        IsCash = true,
                        gender = IsPedMale(mount) and 'male' or 'female',
                        mount = mount
                    }

                    local canKeep = Core.Callback.TriggerAwait('bcc-stables:RegisterHorse', tameData)
                    if canKeep then
                        SetHorseName(tameData)
                    else
                        HorseBreed = false
                    end
                end
            end
        end
        ::END::
        Wait(sleep)
    end
end)

AddEventHandler('bcc-stables:HorseMonitor', function()
    local intervalValue = Config.saveInterval * 1000
    local interval = intervalValue
    local checkInterval = 1000

    while MyHorse ~= 0 do
        Wait(checkInterval)

        interval = interval - checkInterval

        if interval <= 0 and not IsFleeing then
            SaveHorseStats(InWrithe)
            interval = intervalValue
        end
    end
end)


AddEventHandler('bcc-stables:ReviveHorse', function()
    local hasItem = Core.Callback.TriggerAwait('bcc-stables:HorseReviveItem')

    if not hasItem then
        Core.NotifyRightTip(_U('noReviver'), 4000)
        return
    end

    if not IsEntityDead(MyHorse) then
        Citizen.InvokeNative(0x356088527D9EBAAD, PlayerPedId(), MyHorse, `s_inv_horsereviver01x`) -- TaskReviveTarget
        TriggerServerEvent('bcc-stables:UpdateHorseStatus', MyHorseId, nil)
        SetEntityHealth(MyHorse, GetEntityMaxHealth(MyHorse), 0)
        SaveHorseStats(true)
        InWrithe = false
    end
end)

function OpenInventory(horsePedId, horseId, isLooting)
    local hasSaddlebags = Citizen.InvokeNative(0xFB4891BD7578CDC1, horsePedId, -2142954459) -- IsMetaPedUsingComponent

    if not isLooting and Config.useSaddlebags and not hasSaddlebags then
        Core.NotifyRightTip(_U('noSaddlebags'), 4000)
        return
    end

    if hasSaddlebags then
        Citizen.InvokeNative(0xCD181A959CFDD7F4, PlayerPedId(), horsePedId, `Interaction_LootSaddleBags`, 0, true) -- TaskAnimalInteraction
    end

    TriggerServerEvent('bcc-stables:OpenInventory', horseId)
end

function FleeHorse()
    IsFleeing = true
    SaveHorseStats(false)

    GetControlOfHorse()

    Citizen.InvokeNative(0x22B0D0E37CCB840D, MyHorse, PlayerPedId(), 150.0, 10000, 6, 3.0) -- TaskSmartFleePed
    Wait(10000)
    DeleteEntity(MyHorse)
    MyHorse = 0
    IsFleeing = false
end

function ReturnHorse()
    local playerPed = PlayerPedId()

    if not MyHorse or MyHorse == 0 then
        Core.NotifyRightTip(_U('noHorse'), 4000)
        return
    end

    if Citizen.InvokeNative(0x460BC76A0E10655E, playerPed) then -- IsPedOnMount
        Citizen.InvokeNative(0x48E92D3DDE23C23A, playerPed, 0, 0, 0, 0, MyHorse) -- TaskDismountAnimal
        while not Citizen.InvokeNative(0x01FEE67DB37F59B2, playerPed) do -- IsPedOnFoot
            Wait(10)
        end
    end

    SaveHorseStats(InWrithe)
    GetControlOfHorse()
    DeleteEntity(MyHorse)
    MyHorse = 0
    Core.NotifyRightTip(_U('horseReturned'), 4000)
end

function GetControlOfHorse()
    while not NetworkHasControlOfEntity(MyHorse) do
        NetworkRequestControlOfEntity(MyHorse)
        Wait(100)
    end
end

AddEventHandler('bcc-stables:HorseBonding', function()
    local trainingDistance = Config.trainingDistance

    while not MaxBonding do
        Wait(5000)

        local playerPed = PlayerPedId()
        local lastLed = Citizen.InvokeNative(0x693126B5D0457D0D, playerPed)   -- GetLastLedMount
        local isLeading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, playerPed) -- IsPedLeadingHorse
        local currentMount = Citizen.InvokeNative(0x4C8B59171957BCF7, playerPed) -- GetLastMount
        local isMounted = Citizen.InvokeNative(0x460BC76A0E10655E, playerPed) -- IsPedOnMount

        if ((lastLed == MyHorse and isLeading) or (MyHorse == currentMount and isMounted)) then
            local currentCoords = GetEntityCoords(MyHorse)

            if LastLoc == nil then
                LastLoc = currentCoords
            else
                local dist = #(LastLoc - currentCoords)
                if dist >= trainingDistance then
                    LastLoc = currentCoords
                    SaveXp('travel')
                end
            end
        end
    end
end)

function SaveXp(xpSource)
    local horseXp = nil
    local updateXp = {
        ['travel'] = Config.horseXpPerCheck,
        ['brush'] = Config.horseXpPerBrush,
        ['feed'] = Config.horseXpPerFeed,
        ['drink'] = Config.horseXpPerDrink
    }

    horseXp = updateXp[xpSource]
    if not horseXp then
        return print('No xpSource Data!')
    end

    Citizen.InvokeNative(0x75415EE0CB583760, MyHorse, 7, horseXp) -- AddAttributePoints

    if Config.showXpMessage then
        Core.NotifyRightTip('+ ' .. horseXp .. ' XP', 2000)
    end

    local maxXp = Citizen.InvokeNative(0x223BF310F854871C, MyHorse, 7) -- GetMaxAttributePoints
    local newXp = Citizen.InvokeNative(0x219DA04BAA9CB065, MyHorse, 7, Citizen.ResultAsInteger()) -- GetAttributePoints

    MaxBonding = newXp >= maxXp

    TriggerServerEvent('bcc-stables:UpdateHorseXp', newXp, MyHorseId)
end

RegisterNetEvent('bcc-stables:BrushHorse', function()
    if not MyHorse or MyHorse == 0 then
        return Core.NotifyRightTip(_U('noHorse'), 4000)
    end

    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

    if distance > 3.5 then
        return Core.NotifyRightTip(_U('tooFar'), 4000)
    end

    ClearPedTasks(playerPed)

    if Config.horsebrush.durability then
        TriggerServerEvent('bcc-stables:HorseBrushDurability')
    end

    Citizen.InvokeNative(0xCD181A959CFDD7F4, playerPed, MyHorse, `Interaction_Brush`, `p_brushHorse02x`, true) -- TaskAnimalInteraction
    Wait(5000)
    Citizen.InvokeNative(0x6585D955A68452A5, MyHorse) -- ClearPedEnvDirt
    Citizen.InvokeNative(0x523C79AEEFCC4A2A, MyHorse, 10, 'ALL') -- ClearPedDamageDecalByZone
    Citizen.InvokeNative(0x8FE22675A5A45817, MyHorse) -- ClearPedBloodDamage

    local health = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue

    local healthBoost = Config.boost.brushHealth
    local staminaBoost = Config.boost.brushStamina

    if healthBoost > 0 then
        local newHealth = math.min(health + healthBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, newHealth) -- SetAttributeCoreValue
    end

    if staminaBoost > 0 then
        local newStamina = math.min(stamina + staminaBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, newStamina) -- SetAttributeCoreValue
    end

    if (Config.horseXpPerBrush > 0) and (not MaxBonding) then
        if not Config.trainerOnly or IsTrainer then
            SaveXp('brush')
        end
    end

    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
end)

RegisterNetEvent('bcc-stables:FeedHorse', function(item)
    if not MyHorse or MyHorse == 0 then
        return Core.NotifyRightTip(_U('noHorse'), 4000)
    end

    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

    if distance > 3.5 then
        Core.NotifyRightTip(_U('tooFar'), 4000)
        return
    end

    ClearPedTasks(playerPed)
    Citizen.InvokeNative(0xCD181A959CFDD7F4, playerPed, MyHorse, `Interaction_Food`, `s_horsnack_haycube01x`, true) -- TaskAnimalInteraction
    TriggerServerEvent('bcc-stables:RemoveItem', item)
    Wait(5000)

    local health = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    local stamina = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue

    local healthBoost = Config.boost.feedHealth
    local staminaBoost = Config.boost.feedStamina

    if healthBoost > 0 then
        local newHealth = math.min(health + healthBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, newHealth) -- SetAttributeCoreValue
    end

    if staminaBoost > 0 then
        local newStamina = math.min(stamina + staminaBoost, 100)
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, newStamina) -- SetAttributeCoreValue
    end

    if (Config.horseXpPerFeed > 0) and (not MaxBonding) then
        if not Config.trainerOnly or IsTrainer then
            SaveXp('feed')
        end
    end

    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Core_Fill_Up', 'Consumption_Sounds', true, 0) -- PlaySoundFrontend
end)

RegisterNetEvent('bcc-stables:FlamingHooves', function()
    if not MyHorse or MyHorse == 0 then
        return Core.NotifyRightTip(_U('noHorse'), 4000)
    end

    if Activated then return end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local horseCoords = GetEntityCoords(MyHorse)

    if #(playerCoords - horseCoords) > 3.5 then
        return Core.NotifyRightTip(_U('tooFar'), 4000)
    end

    ClearPedTasks(playerPed)

    Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 207, true) -- SetPedConfigFlag / PCF_FlamingHoovesActive
    Core.NotifyRightTip(_U('flameHoovesActivated'), 4000)
    Activated = true

    -- Check if durability system is enabled before adjusting durability
    if Config.flamingHooves.durability then
        TriggerServerEvent('bcc-stables:FlamingHoovesDurability')
    end

    -- Set a timer to deactivate the flaming hooves effect after the specified duration
    local duration = Config.flamingHooves.duration * 60000 -- Convert minutes to milliseconds
    Citizen.SetTimeout(duration, function()
        if DoesEntityExist(MyHorse) then
            Citizen.InvokeNative(0x1913FE4CBF41C463, MyHorse, 207, false)
            Core.NotifyRightTip(_U('flameHoovesDeactivated'), 4000)
            Activated = false
        end
    end)
end)

RegisterNetEvent('bcc-stables:UseLantern', function()
    if not MyHorse or MyHorse == 0 then
        return Core.NotifyRightTip(_U('noHorse'), 4000)
    end

    local playerPed = PlayerPedId()
    local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(MyHorse))

    if distance > 3.5 then
        return Core.NotifyRightTip(_U('tooFar'), 4000)
    end

    ClearPedTasks(playerPed)

    if not UsingLantern then
        SetComponent(MyHorse, 0x635E387C)
        UsingLantern = true

        if Config.lantern.durability then
            TriggerServerEvent('bcc-stables:LanternDurability')
        end
    else
        Citizen.InvokeNative(0x0D7FFA1B2F69ED82, MyHorse, 0x635E387C, 0, 0) -- RemoveShopItemFromPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)    -- UpdatePedVariation
        UsingLantern = false
    end
end)

AddEventHandler('bcc-stables:TradeHorse', function()
    while MyHorse ~= 0 do
        local playerPed = PlayerPedId()
        local sleep = 1000
        local lastLed = Citizen.InvokeNative(0x693126B5D0457D0D, playerPed) -- GetLastLedMount
        local isLeading = Citizen.InvokeNative(0xEFC4303DDC6E60D3, playerPed) -- IsPedLeadingHorse

        if not IsEntityDead(playerPed) and lastLed == MyHorse and isLeading then
            local closestPlayer, closestDistance = GetClosestPlayer()
            if closestPlayer and closestDistance <= 2.0 then
                sleep = 0
                UiPromptSetActiveGroupThisFrame(TradeGroup, CreateVarString(10, 'LITERAL_STRING', HorseName), 1, 0, 0, 0)
                if Citizen.InvokeNative(0xE0F65F0640EF0617, TradeHorse) then  -- PromptHasHoldModeCompleted
                    local serverId = GetPlayerServerId(closestPlayer)
                    TriggerServerEvent('bcc-stables:SaveHorseTrade', serverId, MyHorseId)
                    FleeHorse()
                    break
                end
            end
        end
        Wait(sleep)
    end
end)

function GetClosestPlayer()
    local players = GetActivePlayers()
    local player = PlayerId()
    local coords = GetEntityCoords(PlayerPedId())
    local closestDistance = math.huge
    local closestPlayer = -1

    for _, playerId in ipairs(players) do
        if playerId ~= player then
            local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
            local distance = #(coords - targetCoords)
            if distance < closestDistance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

-- Select Horse Tack from Menu
RegisterNUICallback('Saddles', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        SaddlesUsing = 0
        RemoveComponent(0xBAA7E618)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        SaddlesUsing = hash
    end
end)

RegisterNUICallback('Saddlecloths', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        SaddleclothsUsing = 0
        RemoveComponent(0x17CEB41A)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        SaddleclothsUsing = hash
    end
end)

RegisterNUICallback('Stirrups', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        StirrupsUsing = 0
        RemoveComponent(0xDA6DADCA)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        StirrupsUsing = hash
    end
end)

RegisterNUICallback('SaddleBags', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        BagsUsing = 0
        RemoveComponent(0x80451C25)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        BagsUsing = hash
    end
end)

RegisterNUICallback('Manes', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        ManesUsing = 0
        RemoveComponent(0xAA0217AB)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        ManesUsing = hash
    end
end)

RegisterNUICallback('Tails', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        TailsUsing = 0
        RemoveComponent(0x17CEB41A)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        TailsUsing = hash
    end
end)

RegisterNUICallback('SaddleHorns', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        SaddleHornsUsing = 0
        RemoveComponent(0x5447332)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        SaddleHornsUsing = hash
    end
end)

RegisterNUICallback('Bedrolls', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        BedrollsUsing = 0
        RemoveComponent(0xEFB31921)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        BedrollsUsing = hash
    end
end)

RegisterNUICallback('Masks', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        MasksUsing = 0
        RemoveComponent(0xD3500E5D)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        MasksUsing = hash
    end
end)

RegisterNUICallback('Mustaches', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        MustachesUsing = 0
        RemoveComponent(0x30DEFDDF)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        MustachesUsing = hash
    end
end)

RegisterNUICallback('Holsters', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        HolstersUsing = 0
        RemoveComponent(0xAC106B30)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        HolstersUsing = hash
    end
end)

RegisterNUICallback('Bridles', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        BridlesUsing = 0
        RemoveComponent(0x94B2E3AF)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        BridlesUsing = hash
    end
end)

RegisterNUICallback('Horseshoes', function(data, cb)
    cb('ok')
    if tonumber(data.id) == -1 then
        HorseshoesUsing = 0
        RemoveComponent(0xFACFC3C0)
    else
        local hash = data.hash
        SetComponent(MyEntity, hash)
        HorseshoesUsing = hash
    end
end)

---@param entity number
---@param hash string
function SetComponent(entity, hash)
    if not DoesEntityExist(entity) then return end

    if hash == 0 then return end

    local comp = tonumber(hash)

    local timeout = 0
    local maxTimeout = 1000
    repeat
        Wait(100)
        timeout = timeout + 1
        if timeout >= maxTimeout then
            break
        end
    until GetNumComponentsInPed(entity) ~= 0

    Citizen.InvokeNative(0xD3A7B003ED343FD9, entity, comp, true, true, true) -- ApplyShopItemToPed

    timeout = 0
    repeat
        Wait(100)
        timeout = timeout + 1
        if timeout >= maxTimeout then
            break
        end
    until GetNumComponentsInPed(entity) ~= 0

    Citizen.InvokeNative(0xCC8CA3E88256E58F, entity, false, true, true, true, false) -- UpdatePedVariation
end

function RemoveComponent(category)
    Citizen.InvokeNative(0xD710A5007C2AC539, MyEntity, category, 0) -- RemoveTagFromMetaPed
    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyEntity, false, true, true, true, false) -- UpdatePedVariation
end

RegisterNUICallback('sellHorse', function(data, cb)
    cb('ok')
    DeleteEntity(MyEntity)
    MyEntity = 0
    Cam = false

    local horseSold = Core.Callback.TriggerAwait('bcc-stables:SellMyHorse', data)
    if horseSold then
        StableMenu()
    end
end)

function SaveHorseStats(dead)
    local healthCore, staminaCore

    if not dead then
        healthCore = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 0, Citizen.ResultAsInteger())  -- GetAttributeCoreValue
        staminaCore = Citizen.InvokeNative(0x36731AC041289BB1, MyHorse, 1, Citizen.ResultAsInteger()) -- GetAttributeCoreValue
    else
        healthCore = Config.death.health
        staminaCore = Config.death.stamina
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, healthCore)  -- SetAttributeCoreValue
        Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 1, staminaCore) -- SetAttributeCoreValue
    end

    Wait(100) -- Wait for the values to be set before saving

    TriggerServerEvent('bcc-stables:SaveHorseStatsToDb', healthCore, staminaCore, MyHorseId)
end

-- View Horses While in Menu
function CreateCamera()
    local siteCfg = Stables[Site]
    local horseCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)

    SetCamCoord(horseCam, siteCfg.horse.camera.x, siteCfg.horse.camera.y, siteCfg.horse.camera.z + 1.1)
    SetCamActive(horseCam, true)
    PointCamAtCoord(horseCam, siteCfg.horse.coords.x + 0.5, siteCfg.horse.coords.y, siteCfg.horse.coords.z)

    DoScreenFadeOut(500)
    Wait(500)
    DoScreenFadeIn(500)

    RenderScriptCams(true, false, 0, false, false, 0)
    Citizen.InvokeNative(0x67C540AA08E4A6F5, 'Leaderboard_Show', 'MP_Leaderboard_Sounds', true, 0) -- PlaySoundFrontend
end

function CameraLighting()
    CreateThread(function()
        local siteCfg = Stables[Site]
        local coords = siteCfg.horse.coords

        while Cam do
            Wait(0)
            Citizen.InvokeNative(0xD2D9E04C0DF927F4, coords.x, coords.y, coords.z + 3, 130, 130, 85, 4.0, 15.0) -- DrawLightWithRange
        end
    end)
end

-- -- Rotate Horses while Viewing
local function Rotation(dir)
    local entity = MyEntity ~= 0 and MyEntity or ShopEntity

    if entity ~= 0 then
        local currentHeading = GetEntityHeading(entity)
        SetEntityHeading(entity, (currentHeading + dir) % 360)
    end
end

RegisterNUICallback('rotate', function(data, cb)
    cb('ok')
    local direction = data.RotateHorse
    local dir = direction == 'left' and 1 or -1

    Rotation(dir)
end)

RegisterCommand(Config.commands.horseRespawn, function(source, args, rawCommand)
    Spawning = false
    WhistleSpawn()
end, false)

RegisterCommand(Config.commands.horseSetWild, function(source, args, rawCommand)
    if Config.devMode then
        local mount = Citizen.InvokeNative(0xE7E11B8DCBED1058, PlayerPedId()) -- GetMount

        Citizen.InvokeNative(0xAEB97D84CDF3C00B, mount, true) -- SetAnimalIsWild
        Citizen.InvokeNative(0xBCC76708E5677E1D, mount, true) -- ClearActiveAnimalOwner
        Citizen.InvokeNative(0x9FF1E042FA597187, mount, 97, false) -- SetAnimalTuningBoolParam
    else
        print('Command used in Developer Mode Only!') -- Not for use on live server
    end
end, false)

RegisterCommand(Config.commands.horseWrithe, function(source, args, rawCommand)
    if Config.devMode then
        Citizen.InvokeNative(0x8C038A39C4A4B6D6, MyHorse, 0, 0) -- TaskAnimalWrithe
    else
        print('Command used in Developer Mode Only!') -- Not for use on live server
    end
end, false)

RegisterCommand(Config.commands.horseInfo, function(source, args, rawCommand)
    if not MyHorse or MyHorse == 0 then
        Core.NotifyRightTip(_U('noHorse'), 4000)
        return
    end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(MyHorse)) <= 3.0 then
        HorseInfoMenu()
    else
        Core.NotifyRightTip(_U('tooFar'), 4000)
    end
end, false)

function StartPrompts()
    -- [Tab 0] ปุ่มเปิดร้าน (G)
    OpenShops = UiPromptRegisterBegin()
    UiPromptSetControlAction(OpenShops, Config.keys.shop)
    UiPromptSetText(OpenShops, CreateVarString(10, 'LITERAL_STRING', _U('shopPrompt')))
    UiPromptSetVisible(OpenShops, true)
    UiPromptSetStandardMode(OpenShops, true)
    
    -- ใส่ Group ไว้เหมือนเดิม เพื่อให้มีชื่อร้านสวยๆ ด้านบน
    UiPromptSetGroup(OpenShops, ShopGroup, 0)
    
    UiPromptRegisterEnd(OpenShops)

    -- [ลบ] ส่วนของ OpenCall และ OpenReturn ทิ้งไปเลยครับ (เพราะมันคือ Tab 1 ที่ทำให้เกิดปุ่ม Q)
    
    -- ส่วนปุ่มอื่นๆ (SellTame, KeepTame, ฯลฯ) ปล่อยไว้ตามเดิมครับ
    SellTame = UiPromptRegisterBegin()
    UiPromptSetControlAction(SellTame, Config.keys.sell)
    UiPromptSetText(SellTame, CreateVarString(10, 'LITERAL_STRING', _U('sellPrompt')))
    UiPromptSetHoldMode(SellTame, 2000)
    UiPromptSetGroup(SellTame, TameGroup, 0)
    UiPromptRegisterEnd(SellTame)

    KeepTame = UiPromptRegisterBegin()
    UiPromptSetControlAction(KeepTame, Config.keys.keep)
    UiPromptSetText(KeepTame, CreateVarString(10, 'LITERAL_STRING', _U('keepPrompt') .. tostring(Config.regCost)))
    UiPromptSetHoldMode(KeepTame, 2000)
    UiPromptSetGroup(KeepTame, TameGroup, 0)
    UiPromptRegisterEnd(KeepTame)

    TradeHorse = UiPromptRegisterBegin()
    UiPromptSetControlAction(TradeHorse, Config.keys.trade)
    UiPromptSetText(TradeHorse, CreateVarString(10, 'LITERAL_STRING', _U('tradePrompt')))
    UiPromptSetVisible(TradeHorse, true)
    UiPromptSetEnabled(TradeHorse, true)
    UiPromptSetHoldMode(TradeHorse, 2000)
    UiPromptSetGroup(TradeHorse, TradeGroup, 0)
    UiPromptRegisterEnd(TradeHorse)

    LootHorse = UiPromptRegisterBegin()
    UiPromptSetControlAction(LootHorse, Config.keys.loot)
    UiPromptSetText(LootHorse, CreateVarString(10, 'LITERAL_STRING', _U('lootHorsePrompt')))
    UiPromptSetVisible(LootHorse, true)
    UiPromptSetEnabled(LootHorse, true)
    UiPromptSetStandardMode(LootHorse, true)
    UiPromptSetGroup(LootHorse, LootGroup, 0)
    UiPromptRegisterEnd(LootHorse)
end

function HorseTargetPrompts(menuGroup)
    local currentLevel = Citizen.InvokeNative(0x147149F2E909323C, MyHorse, 7, Citizen.ResultAsInteger()) -- GetAttributeBaseRank

    if not PromptsStarted then
        HorseDrink = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseDrink, Config.keys.drink)
        UiPromptSetText(HorseDrink, CreateVarString(10, 'LITERAL_STRING', _U('drinkPrompt')))
        UiPromptSetVisible(HorseDrink, true)
        UiPromptSetStandardMode(HorseDrink, true)
        UiPromptSetGroup(HorseDrink, menuGroup, 0)
        UiPromptRegisterEnd(HorseDrink)

        HorseRest = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseRest, Config.keys.rest)
        UiPromptSetText(HorseRest, CreateVarString(10, 'LITERAL_STRING', _U('restPrompt')))
        UiPromptSetVisible(HorseRest, true)
        UiPromptSetStandardMode(HorseRest, true)
        UiPromptSetGroup(HorseRest, menuGroup, 0)
        UiPromptRegisterEnd(HorseRest)

        HorseSleep = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseSleep, Config.keys.sleep)
        UiPromptSetText(HorseSleep, CreateVarString(10, 'LITERAL_STRING', _U('sleepPrompt')))
        UiPromptSetVisible(HorseSleep, true)
        UiPromptSetStandardMode(HorseSleep, true)
        UiPromptSetGroup(HorseSleep, menuGroup, 0)
        UiPromptRegisterEnd(HorseSleep)

        HorseWallow = UiPromptRegisterBegin()
        UiPromptSetControlAction(HorseWallow, Config.keys.wallow)
        UiPromptSetText(HorseWallow, CreateVarString(10, 'LITERAL_STRING', _U('wallowPrompt')))
        UiPromptSetVisible(HorseWallow, true)
        UiPromptSetStandardMode(HorseWallow, true)
        UiPromptSetGroup(HorseWallow, menuGroup, 0)
        UiPromptRegisterEnd(HorseWallow)

        PromptsStarted = true
    end

    local prompts = {
        {level = 1, prompt = HorseDrink},
        {level = 2, prompt = HorseRest},
        {level = 3, prompt = HorseSleep},
        {level = 4, prompt = HorseWallow}
    }

    for _, item in ipairs(prompts) do
        UiPromptSetEnabled(item.prompt, currentLevel >= item.level)
    end
end

function CheckPlayerJob(trainer, site)
    local result = Core.Callback.TriggerAwait('bcc-stables:CheckJob', trainer, site)

    IsTrainer = false
    HasJob = false

    if result then
        if trainer and result[1] then
            IsTrainer = true
        elseif result[1] then
            HasJob = true
        end

        if not trainer and result[2] then
            JobMatchedHorses = FindHorsesByJob(result[2])
        end

        if not trainer and not result[1] and Stables[site].shop.jobsEnabled then
            Core.NotifyRightTip(_U('needJob'), 4000)
        end
    end
end

function AddTrainerBlip(site)
    local siteCfg = Trainers[site]

    siteCfg.TrainerBlip = Citizen.InvokeNative(0x554d9d53f696d002, 1664425300, siteCfg.npc.coords) -- BlipAddForCoords
    SetBlipSprite(siteCfg.TrainerBlip, siteCfg.blip.sprite, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, siteCfg.TrainerBlip,  siteCfg.blip.name) -- SetBlipName
end

function AddTrainerNPC(site)
    local siteCfg = Trainers[site]
    local coords = siteCfg.npc.coords

    local modelName = siteCfg.npc.model
    local model = joaat(modelName)
    LoadModel(model, modelName)

    siteCfg.TrainerNPC = CreatePed(model, coords.x, coords.y, coords.z - 1.0, siteCfg.npc.heading, false, false, false, false)
    Citizen.InvokeNative(0x283978A15512B2FE, siteCfg.TrainerNPC, true) -- SetRandomOutfitVariation
    SetEntityCanBeDamaged(siteCfg.TrainerNPC, false)
    SetEntityInvincible(siteCfg.TrainerNPC, true)
    Wait(500)
    FreezeEntityPosition(siteCfg.TrainerNPC, true)
    SetBlockingOfNonTemporaryEvents(siteCfg.TrainerNPC, true)
end

function LoadModel(model, modelName)
    if not IsModelValid(model) then
        return print('Invalid model:', modelName)
    end

    if not HasModelLoaded(model) then
        RequestModel(model, false)

        local timeout = 10000
        local startTime = GetGameTimer()

        while not HasModelLoaded(model) do
            if GetGameTimer() - startTime > timeout then
                print('Failed to load model:', modelName)
                return
            end
            Wait(10)
        end
    end
end

 -- Update Global Horse Entity after session change
RegisterNetEvent('bcc-stables:UpdateMyHorseEntity', function()
    if MyHorse ~= 0 then
        MyHorse = NetworkGetEntityFromNetworkId(LocalPlayer.state.HorseData.MyHorse)
    end
end)

-- to count length of maps
local function len(t)
    local counter = 0
    for _ in pairs(t) do
        counter = counter + 1
    end
    return counter
end

-- to generate ordered index
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex)
    return orderedIndex
end

-- to get the next ordered pair
local function orderedNext(t, state)
    if state == nil then
        t.__orderedIndex = __genOrderedIndex(t)
        t.__index = 1
    else
        t.__index = t.__index + 1
    end

    local key = t.__orderedIndex[t.__index]
    if key then
        return key, t[key]
    end

    t.__orderedIndex = nil
    t.__index = nil
    return
end

-- to get ordered pairs
local function orderedPairs(t)
    return orderedNext, t, nil
end

function FindHorsesByJob(job)
    local matchingHorses = {}
    for _, horseType in ipairs(Horses) do
        local matchingColors = {}

        for horseColor, horseColorData in orderedPairs(horseType.colors) do
            local horseJobs = {}
            for _, horseJob in pairs(horseColorData.job) do
                horseJobs[horseJob] = true
            end

            -- เตรียมข้อมูลของแต่ละสี
            local horseInfo = {
                color = horseColorData.color,
                cashPrice = horseColorData.cashPrice,
                goldPrice = horseColorData.goldPrice,
                itemPrice = horseColorData.itemPrice,
                invLimit = horseColorData.invLimit,
                job = horseColorData.job
            }

            -- [แก้ไข] รวมเงื่อนไข: แสดงเมื่อ (มีอาชีพตรง) หรือ (ม้านั้นไม่จำกัดอาชีพ)
            if horseJobs[job] or len(horseJobs) == 0 then
                matchingColors[horseColor] = horseInfo
            end
        end

        if len(matchingColors) > 0 then
            -- [ส่วนที่เพิ่ม] ดึงค่า Stats ทั้ง 6 ค่าจาก Config
            local statsData = {
                health = 0,
                stamina = 0,
                courage = 0,
                agility = 0,
                speed = 0,
                acceleration = 0
            }

            -- ตรวจสอบว่ามี Config ของ Breed นี้ไหม
            if Config.HorseStats and Config.HorseStats[horseType.breed] then
                local cfg = Config.HorseStats[horseType.breed]
                
                -- ดึงค่ามาใส่ (ถ้าไม่มีใน config ให้เป็น 0)
                statsData.health = cfg.health or 0
                statsData.stamina = cfg.stamina or 0
                statsData.courage = cfg.courage or 0
                statsData.agility = cfg.agility or 0
                statsData.speed = cfg.speed or 0
                statsData.acceleration = cfg.acceleration or 0
            end
            -- [จบส่วนที่เพิ่ม]

            table.insert(matchingHorses, {
                breed = horseType.breed,
                stats = statsData, -- ส่งข้อมูล Stats ไปด้วย
                colors = matchingColors
            })
        end
    end
    return matchingHorses
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if InMenu then
        SendNUIMessage({ action = 'hide' })
        SetNuiFocus(false, false)
    end

    ClearPedTasksImmediately(PlayerPedId())
    DestroyAllCams(true)
    DisplayRadar(true)

    if ShopEntity ~= 0 then
        DeleteEntity(ShopEntity)
        ShopEntity = 0
    end

    if MyEntity ~= 0 then
        DeleteEntity(MyEntity)
        MyEntity = 0
    end

    if MyHorse ~= 0 then
        DeleteEntity(MyHorse)
        MyHorse = 0
    end

    for _, siteCfg in pairs(Stables) do
        if siteCfg.Blip then
            RemoveBlip(siteCfg.Blip)
            siteCfg.Blip = nil
        end
        if siteCfg.NPC then
            DeleteEntity(siteCfg.NPC)
            siteCfg.NPC = nil
        end
    end

    for _, siteCfg in pairs(Trainers) do
        if siteCfg.TrainerBlip then
            RemoveBlip(siteCfg.TrainerBlip)
            siteCfg.TrainerBlip = nil
        end
        if siteCfg.TrainerNPC then
            DeleteEntity(siteCfg.TrainerNPC)
            siteCfg.TrainerNPC = nil
        end
    end

    CleanupAnimalInfoHud()
end)

function OpenDashboard(site)
    -- 1. เช็ค Job ก่อน
    CheckPlayerJob(false, site)
    if not HasJob and Stables[site].shop.jobsEnabled then return end

    -- 2. ตั้งค่าตัวแปรสถานที่
    Site = site
    StableName = Stables[Site].shop.name
    
    -- [สำคัญ] 3. ตัดเข้าฉากทันที (สร้างกล้อง + ซ่อนแผนที่)
    DisplayRadar(false)       -- ซ่อนแผนที่
    InMenu = true             -- บอกระบบว่าอยู่ในเมนูแล้ว
    CreateCamera()            -- สร้างกล้องโรงม้าทันที!
    
    -- ถ้าอยากให้มีแสงส่องม้าเลย ให้เปิดระบบไฟด้วย
    if not Cam then
        Cam = true
        CameraLighting()
    end

    -- 4. ดึงข้อมูลม้า (ขั้นตอนนี้อาจใช้เวลาเสี้ยววินาที แต่กล้องเราตัดไปรอแล้ว)
    local myHorses = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
    
    -- เตรียมข้อมูลม้าในร้าน
    local shopHorses = {}
    -- ใช้เงื่อนไขเดิม หรือปรับตามต้องการ
    if HasJob and Stables[site].shop.jobsEnabled then
        local result = Core.Callback.TriggerAwait('bcc-stables:CheckJob', false, site)
        if result and result[2] then
             shopHorses = FindHorsesByJob(result[2])
        end
    else
        -- ดึงม้าทั้งหมดถ้าไม่ล็อค Job
        shopHorses = FindHorsesByJob(nil) 
    end

    -- 5. ส่งข้อมูลเปิดหน้าเว็บ
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'OPEN_DASHBOARD',
        data = {
            location = StableName,
            myHorses = myHorses,
            shopHorses = shopHorses,
            compData = HorseComp,
            currencyType = Config.currencyType,
            translations = Translations
        }
    })
end

RegisterNUICallback('horseAction', function(data, cb)
    cb('ok')
    local action = data.action
    local horseId = tonumber(data.horseId) -- [แนะนำ] แปลงเป็นตัวเลขเสมอ เพื่อให้เช็คเงื่อนไขได้ถูกต้อง

    -- 1. CALL HORSE
    if action == 'call' then
        local horseData = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        local targetHorse = nil
        for _, h in ipairs(horseData) do
            if tonumber(h.id) == horseId then targetHorse = h break end
        end

        if targetHorse then
            TriggerServerEvent('bcc-stables:SelectHorse', { horseId = horseId })
            Wait(200)
            SpawnHorse(targetHorse)
            Core.NotifyRightTip("Horse Called", 4000)
        end

    -- 2. RETURN HORSE
    elseif action == 'return' then
        ReturnHorse()

    -- 3. DECORATE
    elseif action == 'decorate' then
        TriggerServerEvent('bcc-stables:SelectHorse', { horseId = horseId })
        Wait(200)
        OpenStable(Site)

    -- 4. HEAL HORSE
    elseif action == 'heal' then
        local success = Core.Callback.TriggerAwait('bcc-stables:HealHorseCash', horseId)
        if success then
            Core.NotifyRightTip("Horse Healed!", 4000)
            if MyHorse ~= 0 and tonumber(MyHorseId) == horseId then
                SetEntityHealth(MyHorse, GetEntityMaxHealth(MyHorse))
                Citizen.InvokeNative(0xC6258F41D86676E0, MyHorse, 0, 100)
            end
        else
            Core.NotifyRightTip("Not enough money!", 4000)
        end

    -- 5. SET MAIN
    elseif action == 'setMain' then
        TriggerServerEvent('bcc-stables:SetFavoriteHorse', horseId)
        Core.NotifyRightTip("Set as Main Horse", 4000)

    -- 6. RELEASE (ส่วนที่คุณแก้ไขมา ถูกต้องแล้วครับ)
    elseif action == 'release' then
        -- เพิ่ม tonumber ครอบ MyHorseId เพื่อความชัวร์ในการเช็ค
        if MyHorse ~= 0 and tonumber(MyHorseId) == horseId then
            DeleteEntity(MyHorse)
            MyHorse = 0
            MyHorseId = nil -- [แนะนำ] เคลียร์ค่า ID ทิ้งด้วย
        end
        
        local success = Core.Callback.TriggerAwait('bcc-stables:ReleaseHorse', { horseId = horseId })
        if success then
            Core.NotifyRightTip("Horse Released", 4000)
            -- ไม่ต้องใส่ StableMenu() ตรงนี้ ถูกต้องแล้วครับ
        end

    -- 7. UNEQUIP ALL
    elseif action == 'unequipAll' then
        TriggerServerEvent('bcc-stables:UnequipComponents', horseId)
        if MyHorse ~= 0 and tonumber(MyHorseId) == horseId then
             local categories = {
                0xBAA7E618, 0x17CEB41A, 0xDA6DADCA, 0x80451C25, 
                0xAA0217AB, 0x5447332, 0xEFB31921, 0xD3500E5D, 
                0x30DEFDDF, 0xAC106B30, 0x94B2E3AF, 0xFACFC3C0
             }
             for _, cat in ipairs(categories) do
                RemoveComponent(cat)
             end
        end
        Core.NotifyRightTip("Unequipped All Items", 4000)

    -- 8. UNEQUIP ONE
    elseif action == 'unequipOne' and data.componentHash then
        -- (ส่วนนี้คุณมี tonumber(horseId) อยู่แล้วในโค้ดเดิม แต่ถ้าแก้บรรทัดบนสุดแล้ว ตัวแปร horseId จะเป็นตัวเลขให้อัตโนมัติ)
        local targetHorseId = horseId 
        local componentToRemove = tonumber(data.componentHash)

        local myHorses = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        local targetHorse = nil
        for _, h in ipairs(myHorses) do
            if tonumber(h.id) == targetHorseId then targetHorse = h break end
        end

        if targetHorse then
            local currentComps = json.decode(targetHorse.components)
            local newComps = {}
            local found = false

            if currentComps then
                for _, hash in ipairs(currentComps) do
                    if tonumber(hash) ~= componentToRemove then
                        table.insert(newComps, tonumber(hash))
                    else
                        found = true
                    end
                end
            end
            
            if found then
                local encoded = json.encode(newComps)
                Core.Callback.TriggerAwait('bcc-stables:UpdateComponents', encoded, targetHorseId)
                
                if MyHorse ~= 0 and tonumber(MyHorseId) == targetHorseId then
                    local categoriesToRemove = {
                        0xBAA7E618, 0x17CEB41A, 0xDA6DADCA, 0x80451C25, 
                        0xAA0217AB, 0x5447332, 0xEFB31921, 0xD3500E5D, 
                        0x30DEFDDF, 0xAC106B30, 0x94B2E3AF, 0xFACFC3C0
                    }
                    for _, cat in ipairs(categoriesToRemove) do
                        Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse, cat, 0)
                    end
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)

                    for _, compHash in ipairs(newComps) do
                        SetComponent(MyHorse, compHash)
                    end
                    Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)
                end
                
                Core.NotifyRightTip("Unequipped Item", 4000)
            end
        end

    -- 9. EQUIP OWNED
    elseif action == 'equipOwned' and data.componentHash then
        local targetHorseId = horseId
        local componentToEquip = tonumber(data.componentHash)
        
        local myHorses = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        local targetHorse = nil
        for _, h in ipairs(myHorses) do
            if tonumber(h.id) == targetHorseId then targetHorse = h break end
        end

        if targetHorse then
            local function isSameCategory(hash1, hash2)
                if not HorseComp then return false end
                for _, items in pairs(HorseComp) do
                    local found1, found2 = false, false
                    for _, item in ipairs(items) do
                        if tonumber(item.hash) == hash1 then found1 = true end
                        if tonumber(item.hash) == hash2 then found2 = true end
                    end
                    if found1 and found2 then return true end
                end
                return false
            end

            local currentComps = json.decode(targetHorse.components) or {}
            local newComps = {}
            
            for _, h in ipairs(currentComps) do
                if not isSameCategory(tonumber(h), componentToEquip) then
                    table.insert(newComps, tonumber(h))
                end
            end
            table.insert(newComps, componentToEquip)

            local encoded = json.encode(newComps)
            Core.Callback.TriggerAwait('bcc-stables:UpdateComponents', encoded, targetHorseId)

            if MyHorse ~= 0 and tonumber(MyHorseId) == targetHorseId then
                local categoriesToRemove = {
                    0xBAA7E618, 0x17CEB41A, 0xDA6DADCA, 0x80451C25, 0xAA0217AB, 0x5447332, 
                    0xEFB31921, 0xD3500E5D, 0x30DEFDDF, 0xAC106B30, 0x94B2E3AF, 0xFACFC3C0
                }
                for _, cat in ipairs(categoriesToRemove) do
                    Citizen.InvokeNative(0xD710A5007C2AC539, MyHorse, cat, 0)
                end
                Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)

                for _, compHash in ipairs(newComps) do
                    SetComponent(MyHorse, compHash)
                end
                Citizen.InvokeNative(0xCC8CA3E88256E58F, MyHorse, false, true, true, true, false)
            end
            
            Core.NotifyRightTip("Equipped Item", 4000)
        end

    -- 10. SAVE OWNED
    elseif action == 'saveOwned' and data.componentHash then
        local targetHorseId = horseId
        local newItemHash = tonumber(data.componentHash)
        
        local myHorses = Core.Callback.TriggerAwait('bcc-stables:GetMyHorses')
        local targetHorse = nil
        for _, h in ipairs(myHorses) do
            if tonumber(h.id) == targetHorseId then targetHorse = h break end
        end

        if targetHorse then
            local currentOwned = {}
            if targetHorse.owned_components and targetHorse.owned_components ~= '[]' then
                currentOwned = json.decode(targetHorse.owned_components) or {}
            end
            
            local exists = false
            for _, h in ipairs(currentOwned) do
                if tonumber(h) == newItemHash then exists = true break end
            end
            
            if not exists then
                table.insert(currentOwned, newItemHash)
                local encoded = json.encode(currentOwned)
                Core.Callback.TriggerAwait('bcc-stables:UpdateOwnedComponents', encoded, targetHorseId)
                print("Saved ownership for item: " .. newItemHash)
            end
        end
    end
end)

-- ฟังก์ชันช่วยสวมใส่ไอเทม (และถอดของเก่าในหมวดเดียวกันออก)
function EquipItemLogic(horse, categoryKey, itemHash)
    -- 1. หาว่า Hash ไหนบ้างที่เป็นหมวดเดียวกัน (เพื่อจะถอดของเก่าออก)
    local hashesInThisCat = {}
    if HorseComp and HorseComp[categoryKey] then
        for _, comp in ipairs(HorseComp[categoryKey]) do
            hashesInThisCat[tonumber(comp.hash)] = true
        end
    end

    local newComps = {}
    local oldComps = {}
    if horse.components and horse.components ~= '[]' then
        oldComps = json.decode(horse.components)
    end

    -- เก็บของเดิมที่ไม่ใช่หมวดนี้ไว้
    for _, h in ipairs(oldComps) do
        if not hashesInThisCat[tonumber(h)] then
            table.insert(newComps, h)
        end
    end

    -- ใส่ของใหม่เข้าไป
    table.insert(newComps, itemHash)

    UpdateHorseComponents(horse, newComps)
end

-- ฟังก์ชันบันทึกรายการว่าเป็นเจ้าของ (Owned)
function SaveOwnedItem(horse, itemHash)
    local currentOwned = {}
    if horse.owned_components and horse.owned_components ~= '[]' then
        currentOwned = json.decode(horse.owned_components) or {}
    end

    -- เช็คว่ามีอยู่แล้วไหม
    local exists = false
    for _, h in ipairs(currentOwned) do
        if tonumber(h) == tonumber(itemHash) then exists = true break end
    end

    if not exists then
        table.insert(currentOwned, itemHash)
        local encoded = json.encode(currentOwned)
        horse.owned_components = encoded -- อัปเดตข้อมูล Local
        Core.Callback.TriggerAwait('bcc-stables:UpdateOwnedComponents', encoded, horse.id)
    end
end

-- ฟังก์ชันช่วยอัปเดตข้อมูลการสวมใส่ (Components)
function UpdateHorseComponents(horse, newCompsTable)
    local encoded = json.encode(newCompsTable)
    horse.components = encoded
    Core.Callback.TriggerAwait('bcc-stables:UpdateComponents', encoded, horse.id)

    if MyHorse ~= 0 and MyHorseId == horse.id then
         -- ลบของเก่าออกให้หมดแล้วใส่ใหม่ (วิธีที่ปลอดภัยสุด)
         local categoriesToRemove = {
            0xBAA7E618, 0x17CEB41A, 0xDA6DADCA, 0x80451C25, 
            0xAA0217AB, 0x5447332, 0xEFB31921, 0xD3500E5D, 
            0x30DEFDDF, 0xAC106B30, 0x94B2E3AF, 0xFACFC3C0
         }
         for _, cat in ipairs(categoriesToRemove) do
            RemoveComponent(cat)
         end
         
         for _, h in ipairs(newCompsTable) do
            SetComponent(MyHorse, h)
         end
    end
end

-- [NEW] NUI Callback for opening horse cargo from the stable menu
RegisterNUICallback('OpenHorseCargo', function(data, cb)
    cb('ok')
    local horseId = data.horseId
    
    -- เรียก Event ไปยัง Server เพื่อเปิดช่องเก็บของ
    -- ข้ามการเช็คกระเป๋า (hasSaddlebags) และ Animation เนื่องจากทำจากเมนู Stable
    TriggerServerEvent('bcc-stables:OpenInventory', horseId)
    
    -- หาก MyHorse ปัจจุบัน (ม้าที่เสกในโลก) เป็นม้าตัวที่กำลังเปิดกระเป๋า
    if MyHorse ~= 0 and MyHorseId == horseId then
        -- ให้ม้าหยุดงานต่าง ๆ (ถ้ามี)
        ClearPedTasksImmediately(MyHorse)
    end
end)

-- 1. เพิ่ม Callback สำหรับรักษา (Heal)
RegisterNUICallback('bcc-stables:HealHorseCash', function(data, cb)
    -- เรียก Server Callback ที่เราเคยสร้างไว้
    local success = Core.Callback.TriggerAwait('bcc-stables:HealHorseCash', data.horseId)
    
    if success then
        Core.NotifyRightTip("Horse Healed!", 4000)
        cb('ok')
    else
        Core.NotifyRightTip("Not enough money!", 4000)
        cb('error')
    end
end)

-- 2. เพิ่ม Callback สำหรับปล่อยม้า (Release)
RegisterNUICallback('bcc-stables:ReleaseHorse', function(data, cb)
    -- เรียก Server Callback
    local success = Core.Callback.TriggerAwait('bcc-stables:ReleaseHorse', data)
    
    if success then
        Core.NotifyRightTip("Horse Released to the wild.", 4000)
        cb('ok')
    else
        Core.NotifyRightTip("Error releasing horse.", 4000)
        cb('error')
    end
end)