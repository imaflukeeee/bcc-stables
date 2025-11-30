local Core = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()
local CooldownData = {}
local DevModeActive = Config.devMode

local function DebugPrint(message)
    if DevModeActive then
        print('^1[DEV MODE] ^4' .. message)
    end
end

if Config.discord.active == true then
    Discord = BccUtils.Discord.setup(Config.discord.webhookURL, Config.discord.title, Config.discord.avatar)
end

local function LogToDiscord(name, description, embeds)
    if Config.discord.active == true then
        Discord:sendMessage(name, description, embeds)
    end
end

local function SetPlayerCooldown(type, charid)
    CooldownData[type .. tostring(charid)] = os.time()
end

Core.Callback.Register('bcc-stables:BuyHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier

    local maxHorses = data.isTrainer and tonumber(Config.maxTrainerHorses) or tonumber(Config.maxPlayerHorses)
    local horseCount = MySQL.query.await('SELECT COUNT(*) as count FROM `player_horses` WHERE `charid` = ? AND `dead` = ?', { charid, 0 })[1].count
    
    if horseCount >= maxHorses then
        Core.NotifyRightTip(src, _U('horseLimit') .. maxHorses .. _U('horses'), 4000)
        return cb(false)
    end

    local model = data.ModelH
    local colorCfg = nil

    for _, horseCfg in pairs(Horses) do
        if horseCfg.colors[model] then
            colorCfg = horseCfg.colors[model]
            break
        end
    end

    if not colorCfg then
        print('Horse model not found in the configuration')
        return cb(false)
    end

    -- ตรวจสอบตามประเภทสกุลเงินที่ส่งมาจาก UI
    if data.currencyType == 'cash' then
        if character.money >= colorCfg.cashPrice then
            cb(true)
        else
            Core.NotifyRightTip(src, _U('shortCash'), 4000)
            cb(false)
        end
    elseif data.currencyType == 'gold' then
        if character.gold >= colorCfg.goldPrice then
            cb(true)
        else
            Core.NotifyRightTip(src, _U('shortGold'), 4000)
            cb(false)
        end
    elseif data.currencyType == 'item' then
        -- ตรวจสอบไอเทม
        if colorCfg.itemPrice then
            local itemCount = exports.vorp_inventory:getItemCount(src, nil, colorCfg.itemPrice.name)
            if itemCount >= colorCfg.itemPrice.amount then
                cb(true)
            else
                Core.NotifyRightTip(src, "Not enough " .. colorCfg.itemPrice.label, 4000)
                cb(false)
            end
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

Core.Callback.Register('bcc-stables:RegisterHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier

    local maxHorses = data.isTrainer and tonumber(Config.maxTrainerHorses) or tonumber(Config.maxPlayerHorses)

    local horseCount = MySQL.query.await('SELECT COUNT(*) as count FROM `player_horses` WHERE `charid` = ? AND `dead` = ?', { charid, 0 })[1].count
    if horseCount >= maxHorses then
        Core.NotifyRightTip(src, _U('horseLimit') .. maxHorses .. _U('horses'), 4000)
        return cb(false)
    end

    if data.IsCash and data.origin == 'tameHorse' then
        if character.money >= Config.regCost then
            return cb(true)
        else
            Core.NotifyRightTip(src, _U('shortCash'), 4000)
            return cb(false)
        end
    end

    cb(false)
end)

Core.Callback.Register('bcc-stables:BuyTack', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local cashPrice = tonumber(data.cashPrice)
    local goldPrice = tonumber(data.goldPrice)

    if cashPrice > 0 and goldPrice > 0 then
        if tonumber(data.currencyType) == 0 then
            if character.money >= cashPrice then
                character.removeCurrency(0, cashPrice)
            else
                Core.NotifyRightTip(src, _U('shortCash'), 4000)
                return cb(false)
            end
        else
            if character.gold >= goldPrice then
                character.removeCurrency(1, goldPrice)
            else
                Core.NotifyRightTip(src, _U('shortGold'), 4000)
                return cb(false)
            end
        end
        Core.NotifyRightTip(src, _U('purchaseSuccessful'), 4000)
        return cb(true)
    end

    cb(false)
end)

Core.Callback.Register('bcc-stables:SaveNewHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local name = data.name
    local model = data.ModelH
    local gender = data.gender
    local captured = data.captured
    local currencyType = data.currencyType -- 'cash', 'gold', 'item'

    for _, horseCfg in pairs(Horses) do
        local colorCfg = horseCfg.colors[model]
        if colorCfg then
            
            local canBuy = false

            -- 1. กรณีใช้เงินสด
            if currencyType == 'cash' and colorCfg.cashPrice and character.money >= colorCfg.cashPrice then
                character.removeCurrency(0, colorCfg.cashPrice)
                canBuy = true

            -- 2. กรณีใช้ทอง
            elseif currencyType == 'gold' and colorCfg.goldPrice and character.gold >= colorCfg.goldPrice then
                character.removeCurrency(1, colorCfg.goldPrice)
                canBuy = true

            -- 3. กรณีใช้ไอเทม
            elseif currencyType == 'item' and colorCfg.itemPrice then
                local itemCount = exports.vorp_inventory:getItemCount(src, nil, colorCfg.itemPrice.name)
                if itemCount >= colorCfg.itemPrice.amount then
                    exports.vorp_inventory:subItem(src, colorCfg.itemPrice.name, colorCfg.itemPrice.amount)
                    canBuy = true
                else
                    Core.NotifyRightTip(src, "Not enough " .. colorCfg.itemPrice.label, 4000)
                end
            end

            -- ถ้าซื้อสำเร็จ ให้บันทึกลงฐานข้อมูล
            if canBuy then
                MySQL.query.await('INSERT INTO `player_horses` (identifier, charid, name, model, gender, captured, components) VALUES (?, ?, ?, ?, ?, ?, ?)',
                { identifier, charid, name, model, gender, captured, '[]' })

                LogToDiscord(charid, _U('discordHorsePurchased'))
                return cb(true)
            else
                -- แจ้งเตือนกรณีเงิน/ของไม่พอ (fallback)
                if currencyType == 'cash' then Core.NotifyRightTip(src, _U('shortCash'), 4000)
                elseif currencyType == 'gold' then Core.NotifyRightTip(src, _U('shortGold'), 4000)
                end
                return cb(false)
            end
        end
    end

    cb(false)
end)

Core.Callback.Register('bcc-stables:SaveTamedHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local regCost = Config.regCost
    local name = data.name
    local model = data.ModelH
    local gender = data.gender
    local captured = data.captured

    if data.IsCash and data.origin == 'tameHorse' then
        if character.money < regCost then
            Core.NotifyRightTip(src, _U('shortCash'), 4000)
            return cb(false)
        end
        character.removeCurrency(0, regCost)
    end

    MySQL.query.await('INSERT INTO `player_horses` (identifier, charid, name, model, gender, captured, components) VALUES (?, ?, ?, ?, ?, ?, ?)',
    { identifier, charid, name, model, gender, captured, '[]' })

    LogToDiscord(charid, _U('discordTamedPurchased'))
    cb(true)
end)

Core.Callback.Register('bcc-stables:UpdateHorseName', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local newName = data.name
    local horseId = data.horseId

    MySQL.query.await('UPDATE `player_horses` SET `name` = ? WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
    { newName, horseId, identifier, charid })

    cb(true)
end)

RegisterNetEvent('bcc-stables:UpdateHorseXp', function(Xp, horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    MySQL.query.await('UPDATE `player_horses` SET `xp` = ? WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
    { Xp, horseId, identifier, charid })

    LogToDiscord(charid, _U('discordHorseXPGain'))
end)

RegisterNetEvent('bcc-stables:SaveHorseStatsToDb', function(health, stamina, id)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local horseHealth = tonumber(health) or 100
    local horseStamina = tonumber(stamina) or 100
    local horseId = tonumber(id)

    print("Saving horse stats to DB:", horseId, horseHealth, horseStamina)
    MySQL.query.await('UPDATE `player_horses` SET `health` = ?, `stamina` = ? WHERE id = ? AND `identifier` = ? AND `charid` = ?',
    { horseHealth, horseStamina, horseId, identifier, charid })
end)

RegisterNetEvent('bcc-stables:SelectHorse', function(data)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local selectedHorseId = data.horseId

    -- Deselect all horses for the character
    MySQL.query.await('UPDATE `player_horses` SET `selected` = ? WHERE `charid` = ? AND `identifier` = ? AND `dead` = ?',
    { 0, charid, identifier, 0 })

    -- Select the specified horse
    MySQL.query.await('UPDATE `player_horses` SET `selected` = ? WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
    { 1, selectedHorseId, charid, identifier })
end)

RegisterNetEvent('bcc-stables:SetHorseWrithe', function(horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    MySQL.query.await('UPDATE `player_horses` SET `writhe` = ? WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
    { 1, horseId, identifier, charid })
end)

-- Update Horse Selected and Dead Status After Death Event
RegisterNetEvent('bcc-stables:UpdateHorseStatus', function(horseId, action)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    local selected = (action == 'deselect') and 0 or 1
    local dead = action == 'dead' and 1 or 0

    MySQL.query.await('UPDATE `player_horses` SET `selected` = ?, `writhe` = ?, `dead` = ? WHERE `id` = ? AND `identifier` = ? AND `charid` = ?',
    { selected, 0, dead, horseId, identifier, charid })
end)

Core.Callback.Register('bcc-stables:GetHorseData', function(source, cb)
    local src = source
    local user = Core.getUser(src)

    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter

    local horses = MySQL.query.await('SELECT * FROM `player_horses` WHERE `charid` = ? AND `identifier` = ?',
    { character.charIdentifier, character.identifier })

    if #horses == 0 then
        Core.NotifyRightTip(src, _U('noHorses'), 4000)
        return cb(false)
    end

    local selectedHorse = nil
    for _, horse in ipairs(horses) do
        if horse.selected == 1 then
            selectedHorse = horse
            break
        end
    end

    if not selectedHorse then
        Core.NotifyRightTip(src, _U('noSelectedHorse'), 4000)
        return cb(false)
    end

    -- [ส่วนที่เพิ่ม/แก้ไข] หา Breed ของม้าเพื่อดึง Stats
    local breedName = "Unknown"
    -- เราต้องวนหา Breed จาก Config Horses โดยใช้ Model
    for _, horseCfg in pairs(Horses) do
        if horseCfg.colors[selectedHorse.model] then
            breedName = horseCfg.breed
            break
        end
    end

    -- เตรียม Default Stats
    local statsData = {
        health = 0, stamina = 0, courage = 0, agility = 0, speed = 0, acceleration = 0
    }

    -- ดึงค่าจาก Config ถ้ามี
    if Config.HorseStats and Config.HorseStats[breedName] then
        local cfg = Config.HorseStats[breedName]
        statsData.health = cfg.health or 0
        statsData.stamina = cfg.stamina or 0
        statsData.courage = cfg.courage or 0
        statsData.agility = cfg.agility or 0
        statsData.speed = cfg.speed or 0
        statsData.acceleration = cfg.acceleration or 0
    end
    -- [จบส่วนที่เพิ่ม]

    cb({
        model = selectedHorse.model,
        name = selectedHorse.name,
        components = selectedHorse.components,
        id = selectedHorse.id,
        gender = selectedHorse.gender,
        xp = selectedHorse.xp,
        captured = selectedHorse.captured,
        health = selectedHorse.health,
        stamina = selectedHorse.stamina,
        writhe = selectedHorse.writhe,
        dead = selectedHorse.dead,
        
        -- ส่งเพิ่มไป
        breed = breedName,
        stats = statsData
    })
end)

Core.Callback.Register('bcc-stables:GetMyHorses', function(source, cb)
    local src = source
    local user = Core.getUser(src)

    if not user then
        DebugPrint('User not found for source: ' .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    local horses = MySQL.query.await('SELECT * FROM `player_horses` WHERE `charid` = ? AND `identifier` = ?', { charid, identifier })

    for i, horse in ipairs(horses) do
        local breedName = "Unknown"
        local invLimit = 0 -- [เพิ่ม] ตัวแปรเก็บค่าความจุ
        
        -- หา Breed และ invLimit
        for _, horseCfg in pairs(Horses) do
            if horseCfg.colors[horse.model] then
                breedName = horseCfg.breed
                -- [เพิ่ม] ดึงค่า invLimit จาก Config
                if horseCfg.colors[horse.model].invLimit then
                    invLimit = horseCfg.colors[horse.model].invLimit
                end
                break
            end
        end

        local statsData = {
            health = 0, stamina = 0, courage = 0, agility = 0, speed = 0, acceleration = 0
        }

        if Config.HorseStats and Config.HorseStats[breedName] then
            local cfg = Config.HorseStats[breedName]
            statsData.health = cfg.health or 0
            statsData.stamina = cfg.stamina or 0
            statsData.courage = cfg.courage or 0
            statsData.agility = cfg.agility or 0
            statsData.speed = cfg.speed or 0
            statsData.acceleration = cfg.acceleration or 0
        end

        horses[i].breed = breedName
        horses[i].stats = statsData
        horses[i].invLimit = invLimit -- [เพิ่ม] ส่งค่าความจุไปด้วย
    end

    cb(horses)
end)

Core.Callback.Register('bcc-stables:UpdateComponents', function(source, cb, encodedComponents, horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    MySQL.query.await('UPDATE `player_horses` SET `components` = ? WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
    { encodedComponents, horseId, charid, identifier })

    cb(true)
end)

-- [NEW] บันทึกรายการของที่เป็นเจ้าของ (Owned Items)
Core.Callback.Register('bcc-stables:UpdateOwnedComponents', function(source, cb, encodedComponents, horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier

    MySQL.query.await('UPDATE `player_horses` SET `owned_components` = ? WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
    { encodedComponents, horseId, charid, identifier })

    cb(true)
end)

Core.Callback.Register('bcc-stables:SellMyHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local model = nil
    local horseId = tonumber(data.horseId)
    local captured = data.captured
    local matchFound = false

    -- Fetch the horse data
    local horses = MySQL.query.await('SELECT `id`, `model` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ? AND `dead` = ?',
    { charid, identifier, 0 })

    -- Find the horse and delete it
    for i = 1, #horses do
        if tonumber(horses[i].id) == horseId then
            matchFound = true
            model = horses[i].model

            MySQL.query.await('DELETE FROM `player_horses` WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
            { horseId, charid, identifier })

            LogToDiscord(charid, _U('discordHorseSold'))
            break
        end
    end

    if not matchFound then return cb(false) end

    -- Determine the sell price
    for _, horseCfg in pairs(Horses) do
        local colorCfg = horseCfg.colors[model]
        if colorCfg then
            local sellPrice = captured and (Config.tamedSellPrice * colorCfg.cashPrice) or (Config.sellPrice * colorCfg.cashPrice)
            character.addCurrency(0, sellPrice)
            Core.NotifyRightTip(src, _U('soldHorse') .. sellPrice, 4000)
            return cb(true)
        end
    end

    cb(false)
end)

RegisterNetEvent('bcc-stables:SellTamedHorse', function(hash)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    local charid = character.charIdentifier
    local sellPriceMultiplier = Config.tamedSellPrice

    for _, horseCfg in pairs(Horses) do
        for color, colorCfg in pairs(horseCfg.colors) do
            local colorHash = joaat(color)
            if colorHash == hash then
                local sellPrice = (sellPriceMultiplier * colorCfg.cashPrice)
                character.addCurrency(0, math.ceil(sellPrice))
                Core.NotifyRightTip(src, _U('soldHorse') .. sellPrice, 4000)
                SetPlayerCooldown('sellTame', charid)
                LogToDiscord(charid, _U('discordTamedSold'))
                return
            end
        end
    end
end)

RegisterNetEvent('bcc-stables:SaveHorseTrade', function(serverId, horseId)
    -- Current Owner
    local src = source
    local curUser = Core.getUser(src)
    if not curUser then return end

    local curOwner = curUser.getUsedCharacter
    local curOwnerId = curOwner.identifier
    local curOwnerCharId = curOwner.charIdentifier
    local curOwnerName = curOwner.firstname .. " " .. curOwner.lastname
    -- New Owner
    local newUser = Core.getUser(serverId)
    if not newUser then return end

    local newOwner = newUser.getUsedCharacter
    local newOwnerId = newOwner.identifier
    local newOwnerCharId = newOwner.charIdentifier
    local newOwnerName = newOwner.firstname .. " " .. newOwner.lastname

    -- Fetch the horse
    local horse = MySQL.query.await('SELECT * FROM `player_horses` WHERE `id` = ? AND `charid` = ? AND `identifier` = ? AND `dead` = ?',
    { horseId, curOwnerCharId, curOwnerId, 0 })

    if horse and #horse > 0 then
        -- Update the horse ownership
        MySQL.query.await('UPDATE `player_horses` SET `identifier` = ?, `charid` = ?, `selected` = ? WHERE `id` = ?',
        { newOwnerId, newOwnerCharId, 0, horseId })

        -- Notify both parties
        Core.NotifyRightTip(src, _U('youGave') .. newOwnerName .. _U('aHorse'), 4000)
        Core.NotifyRightTip(serverId, curOwnerName .._U('gaveHorse'), 4000)

        LogToDiscord(curOwnerName, _U('discordTraded') .. newOwnerName)
    end
end)

RegisterNetEvent('bcc-stables:RegisterInventory', function(id, model)
    local idStr = 'horse_' .. tostring(id)
    local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(idStr)

    -- [แก้ไขใหม่] 1. ดึงชื่อม้าจากฐานข้อมูล
    local horseName = _U('horseInv') -- ค่าเริ่มต้น (Saddlebags)
    local result = MySQL.query.await('SELECT name FROM player_horses WHERE id = ?', {id})
    if result and result[1] and result[1].name then
        horseName = result[1].name -- ใช้ชื่อม้าถ้าหาเจอ
    end
    -- [จบส่วนแก้ไข]

    for _, horseCfg in pairs(Horses) do
        if horseCfg.colors[model] then
            local colorCfg = horseCfg.colors[model]
            local data = {
                id = idStr,
                name = horseName, -- [แก้ไขใหม่] 2. เปลี่ยนตรงนี้จาก _U('horseInv') เป็นตัวแปร horseName
                limit = tonumber(colorCfg.invLimit),
                acceptWeapons = Config.allowWeapons,
                shared = Config.shareInventory,
                ignoreItemStackLimit = Config.ignoreItemStackLimit or true,
                whitelistItems =  Config.useWhiteList or false,
                UsePermissions = Config.usePermissions or false,
                UseBlackList = Config.useBlackList or false,
                whitelistWeapons = Config.whitelistWeapons or false
            }

            if isRegistered then
                exports.vorp_inventory:updateCustomInventoryData(idStr, data)
            else
                exports.vorp_inventory:registerInventory(data)
            end

            if data.UsePermissions then
                for _, permission in ipairs(Config.permissions.allowedJobsTakeFrom) do
                    exports.vorp_inventory:AddPermissionTakeFromCustom(idStr, permission.name, permission.grade)
                end
                for _, permission in ipairs(Config.permissions.allowedJobsMoveTo) do
                    exports.vorp_inventory:AddPermissionMoveToCustom(idStr, permission.name, permission.grade)
                end
            end

            if data.whitelistItems then
                for _, item in ipairs(Config.itemsLimitWhiteList) do
                    exports.vorp_inventory:setCustomInventoryItemLimit(idStr, item.name, item.limit)
                end
            end

            if data.whitelistWeapons then
                for _, weapon in ipairs(Config.weaponsLimitWhiteList) do
                    exports.vorp_inventory:setCustomInventoryWeaponLimit(idStr, weapon.name, weapon.limit)
                end
            end

            if data.UseBlackList then
                for _, item in ipairs(Config.itemsBlackList) do
                    exports.vorp_inventory:BlackListCustomAny(idStr, item)
                end
            end
            break
        end
    end
end)

RegisterNetEvent('bcc-stables:OpenInventory', function(id)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local idStr = 'horse_' .. tostring(id)
    exports.vorp_inventory:openInventory(src, idStr)
end)

-- Iterate over each item in the Config.horseFood array to register them as usable items
for _, item in ipairs(Config.horseFood) do
    exports.vorp_inventory:registerUsableItem(item, function(data)
        local src = data.source
        exports.vorp_inventory:closeInventory(src)

        TriggerClientEvent('bcc-stables:FeedHorse', src, item)
    end)
end

if Config.flamingHooves.active then
    exports.vorp_inventory:registerUsableItem(Config.flamingHooves.item, function(data)
        local src = data.source
        local user = Core.getUser(src)
        if not user then return end

        local item = exports.vorp_inventory:getItem(src, Config.flamingHooves.item)
        exports.vorp_inventory:closeInventory(src)

        if Config.flamingHooves.durability then
            local maxDurability = Config.flamingHooves.maxDurability or 100
            local useDurability = Config.flamingHooves.durabilityPerUse or 1
            local itemMetadata = item.metadata
            local currentDurability = itemMetadata.durability

            -- Initialize durability if it doesn't exist
            if not currentDurability then
                currentDurability = maxDurability
                local newData = {
                    description = _U('flameHooveDesc') .. '</br>' .. _U('durability') .. currentDurability .. '%',
                    durability = currentDurability,
                    id = item.id
                }
                exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
            end

            -- Check if durability is below the usage threshold
            if currentDurability < useDurability then
                exports.vorp_inventory:subItemID(src, item.id)
                Core.NotifyRightTip(src, _U('itemBroke'), 4000)
                return
            end
        end

        TriggerClientEvent('bcc-stables:FlamingHooves', src)
    end)

    RegisterNetEvent('bcc-stables:FlamingHoovesDurability', function()
        local src = source
        local user = Core.getUser(src)
        if not user then return end

        local item = exports.vorp_inventory:getItem(src, Config.flamingHooves.item)
        local useDurability = Config.flamingHooves.durabilityPerUse or 1
        local itemMetadata = item.metadata
        local newDurability = itemMetadata.durability - useDurability

        -- Check if durability is below the usage threshold or update the durability
        if newDurability < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
        else
            local newData = {
                description = _U('flameHooveDesc') .. '</br>' .. _U('durability') .. newDurability .. '%',
                durability = newDurability,
                id = item.id
            }
            exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
        end
    end)
end

RegisterNetEvent('bcc-stables:RemoveItem', function(item)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    exports.vorp_inventory:subItem(src, item, 1)
end)

exports.vorp_inventory:registerUsableItem(Config.horsebrush.item, function(data)
    local src = data.source
    local user = Core.getUser(src)
    if not user then return end

    local item = exports.vorp_inventory:getItem(src, Config.horsebrush.item)
    exports.vorp_inventory:closeInventory(src)

    if Config.horsebrush.durability then
        local maxDurability = Config.horsebrush.maxDurability or 100
        local useDurability = Config.horsebrush.durabilityPerUse or 1
        local itemMetadata = item.metadata
        local currentDurability = itemMetadata.durability

        -- Initialize durability if it doesn't exist
        if not currentDurability then
            currentDurability = maxDurability
            local newData = {
                description = _U('horsebrushDesc') .. '</br>' .. _U('durability') .. currentDurability .. '%',
                durability = currentDurability,
                id = item.id
            }
            exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
        end

        -- Check if durability is below the usage threshold
        if currentDurability < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
            return
        end
    end

    TriggerClientEvent('bcc-stables:BrushHorse', src)
end)

RegisterNetEvent('bcc-stables:HorseBrushDurability', function()
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local item = exports.vorp_inventory:getItem(src, Config.horsebrush.item)
    local useDurability = Config.horsebrush.durabilityPerUse or 1
    local itemMetadata = item.metadata
    local newDurability = itemMetadata.durability - useDurability

    -- Check if durability is below the usage threshold or update the durability
    if newDurability < useDurability then
        exports.vorp_inventory:subItemID(src, item.id)
        Core.NotifyRightTip(src, _U('itemBroke'), 4000)
    else
        local newData = {
            description = _U('horsebrushDesc') .. '</br>' .. _U('durability') .. newDurability .. '%',
            durability = newDurability,
            id = item.id
        }
        exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
    end
end)

exports.vorp_inventory:registerUsableItem(Config.lantern.item, function(data)
    local src = data.source
    local user = Core.getUser(src)
    if not user then return end

    local item = exports.vorp_inventory:getItem(src, Config.lantern.item)
    exports.vorp_inventory:closeInventory(src)

    if Config.lantern.durability then
        local maxDurability = Config.lantern.maxDurability or 100
        local useDurability = Config.lantern.durabilityPerUse or 1
        local itemMetadata = item.metadata
        local currentDurability = itemMetadata.durability

        -- Initialize durability if it doesn't exist
        if not currentDurability then
            currentDurability = maxDurability
            local newData = {
                description = _U('lanternDesc') .. '</br>' .. _U('durability') .. currentDurability .. '%',
                durability = currentDurability,
                id = item.id
            }
            exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
        end

        -- Check if durability is below the usage threshold
        if currentDurability < useDurability then
            exports.vorp_inventory:subItemID(src, item.id)
            Core.NotifyRightTip(src, _U('itemBroke'), 4000)
            return
        end
    end

    TriggerClientEvent('bcc-stables:UseLantern', src)
end)

RegisterNetEvent('bcc-stables:LanternDurability', function()
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local item = exports.vorp_inventory:getItem(src, Config.lantern.item)
    local useDurability = Config.lantern.durabilityPerUse or 1
    local itemMetadata = item.metadata
    local newDurability = itemMetadata.durability - useDurability

    -- Check if durability is below the usage threshold or update the durability
    if newDurability < useDurability then
        exports.vorp_inventory:subItemID(src, item.id)
        Core.NotifyRightTip(src, _U('itemBroke'), 4000)
    else
        local newData = {
            description = _U('lanternDesc') .. '</br>' .. _U('durability') .. newDurability .. '%',
            durability = newDurability,
            id = item.id
        }
        exports.vorp_inventory:setItemMetadata(src, item.id, newData, 1)
    end
end)

Core.Callback.Register('bcc-stables:HorseReviveItem', function(source, cb)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local reviveItem = Config.reviver
    local hasItem = exports.vorp_inventory:getItem(src, reviveItem)

    if not hasItem then
        return cb(false)
    end

    exports.vorp_inventory:subItem(src, reviveItem, 1)
    cb(true)
end)

Core.Callback.Register('bcc-stables:CheckPlayerCooldown', function(source, cb, type)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local cooldown = Config.cooldown[type]
    local typeId = type .. tostring(character.charIdentifier)
    local currentTime = os.time()
    local lastTime = CooldownData[typeId]

    if lastTime then
        if os.difftime(currentTime, lastTime) >= cooldown * 60 then
            cb(false) -- Not on Cooldown
        else
            cb(true) -- On Cooldown
        end
    else
        cb(false) -- Not on Cooldown
    end
end)

Core.Callback.Register('bcc-stables:CheckJob', function(source, cb, trainer, site)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local jobConfig = trainer and Config.trainerJob or Stables[site].shop.jobs

    local hasJob = false
    for _, job in pairs(jobConfig) do
        if (character.job == job.name) and (tonumber(character.jobGrade) >= tonumber(job.grade)) then
            hasJob = true
            break
        end
    end

    cb({hasJob, character.job})
end)

RegisterNetEvent('vorp_core:instanceplayers', function(setRoom)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    if setRoom == 0 then
        Wait(3000)
        TriggerClientEvent('bcc-stables:UpdateMyHorseEntity', src)
    end
end)

--- Check if properly downloaded
function file_exists(name)
    local f = LoadResourceFile(GetCurrentResourceName(), name)
    return f ~= nil
end

if not file_exists('./ui/index.html') then
    print('^1 INCORRECT DOWNLOAD!  ^0')
    print(
        '^4 Please Download: ^2(bcc-stables.zip) ^4from ^3<https://github.com/BryceCanyonCounty/bcc-stables/releases/latest>^0')
end

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-stables')

Core.Callback.Register('bcc-stables:ReviveAtStable', function(source, cb)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end
    
    local character = user.getUsedCharacter
    local cost = Config.ReviveCost or 10.0

    if character.money >= cost then
        character.removeCurrency(0, cost) -- ตัดเงิน
        
        -- อัปเดตฐานข้อมูลให้ม้าหายตาย
        MySQL.query.await('UPDATE `player_horses` SET `dead` = 0, `health` = 100, `writhe` = 0 WHERE `charid` = ? AND `identifier` = ? AND `selected` = 1',
        { character.charIdentifier, character.identifier })
        
        cb(true)
    else
        cb(false)
    end
end)

-- [NEW] 1. Heal Horse System
Core.Callback.Register('bcc-stables:HealHorseCash', function(source, cb, horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end
    local character = user.getUsedCharacter
    local cost = Config.ReviveCost or 20.0 -- Use cost from Config or default 20.0

    if character.money >= cost then
        character.removeCurrency(0, cost) -- Remove Cash
        -- Update status: Alive, Not Injured, Full Health, Full Stamina
        MySQL.query.await('UPDATE `player_horses` SET `dead` = 0, `writhe` = 0, `health` = 100, `stamina` = 100 WHERE `id` = ?', { horseId })
        cb(true)
    else
        cb(false) -- Not enough money
    end
end)

-- [NEW] 2. Set Favorite/Main Horse System
RegisterNetEvent('bcc-stables:SetFavoriteHorse', function(horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return end
    local charid = user.getUsedCharacter.charIdentifier
    local identifier = user.getUsedCharacter.identifier

    -- Deselect all horses first
    MySQL.query.await('UPDATE `player_horses` SET `selected` = 0 WHERE `charid` = ? AND `identifier` = ?', { charid, identifier })
    
    -- Set new favorite horse
    MySQL.query.await('UPDATE `player_horses` SET `selected` = 1 WHERE `id` = ? AND `charid` = ?', { horseId, charid })
    
    Core.NotifyRightTip(src, "Horse set as Main", 4000)
end)

-- [NEW] 3. Unequip All Components System
RegisterNetEvent('bcc-stables:UnequipComponents', function(horseId)
    local src = source
    local user = Core.getUser(src)
    if not user then return end
    
    -- Clear components array
    MySQL.query.await('UPDATE `player_horses` SET `components` = ? WHERE `id` = ?', { '[]', horseId })
    
    Core.NotifyRightTip(src, "All equipment removed", 4000)
end)

-- [NEW] 4. Release Horse (Delete without refund)
Core.Callback.Register('bcc-stables:ReleaseHorse', function(source, cb, data)
    local src = source
    local user = Core.getUser(src)
    if not user then return cb(false) end

    local character = user.getUsedCharacter
    local identifier = character.identifier
    local charid = character.charIdentifier
    local horseId = tonumber(data.horseId)
    local matchFound = false

    -- ตรวจสอบว่าเป็นเจ้าของม้าจริงไหม
    local horses = MySQL.query.await('SELECT `id` FROM `player_horses` WHERE `charid` = ? AND `identifier` = ?',
    { charid, identifier })

    -- วนลูปหาและลบม้า
    for i = 1, #horses do
        if tonumber(horses[i].id) == horseId then
            matchFound = true

            MySQL.query.await('DELETE FROM `player_horses` WHERE `id` = ? AND `charid` = ? AND `identifier` = ?',
            { horseId, charid, identifier })

            -- บันทึกลง Discord ว่าปล่อยม้า (ถ้าเปิดใช้)
            LogToDiscord(charid, "Released a horse (Deleted)")
            break
        end
    end

    if not matchFound then return cb(false) end

    -- แจ้งเตือนและจบการทำงาน (โดยไม่คืนเงิน)
    Core.NotifyRightTip(src, "Released Horse to the wild", 4000)
    return cb(true)
end)