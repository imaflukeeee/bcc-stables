-- config/z_horsestats.lua
Config = Config or {}

-- ค่า Base Rank (แนะนำ 1-10 หรือมากกว่าตามต้องการ)
Config.HorseStats = {
    ['Morgan'] = {
        health = 10,         -- Rank 0
        stamina = 10,        -- Rank 1
        courage = 10,        -- Rank 3 (ความกล้า)
        agility = 10,        -- Rank 4 (การเลี้ยว)
        speed = 10,          -- Rank 5
        acceleration = 10    -- Rank 6
    },
    ['American Paint'] = {
        health = 8,
        stamina = 9,
        courage = 10,
        agility = 10,
        speed = 10,
        acceleration = 10
    },
    ['Tennessee Walker'] = {
        health = 5,
        stamina = 6,
        courage = 6,
        agility = 5,
        speed = 8,
        acceleration = 7
    },
    -- เพิ่ม Breed อื่นๆ ได้ตามชื่อใน config/horses.lua
}