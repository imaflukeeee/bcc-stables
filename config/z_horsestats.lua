-- config/horsestats.lua

Config = Config or {}

-- กำหนดค่าพลังตามสายพันธุ์ (MyHorseBreed)
-- Speed/Accel/Handling: ค่าแนะนำ 0 - 10
-- HP/Stamina: ค่าปกติ 100-150 (ถ้าอยากให้อึดมากใส่ 300-500)

Config.HorseStats = {
    ['Arabian'] = {
        speed = 9,          -- ความเร็วสูง
        accel = 9,          -- เร่งไว
        handling = 8,       -- การควบคุมระดับ Elite (เลี้ยวไว)
        hp = 300,
        stamina = 100
    },
    ['Thoroughbred'] = {
        speed = 8,
        accel = 7,
        handling = 5,       -- การควบคุมระดับ Race
        hp = 200,
        stamina = 200
    },
    ['Shire'] = {
        speed = 3,          -- ช้า
        accel = 2,          -- ออกตัวอืด
        handling = 0,       -- การควบคุมระดับ Heavy (เลี้ยวยาก)
        hp = 500,           -- เลือดเยอะมาก (สายถึก)
        stamina = 250
    },
    ['Morgan'] = {
        speed = 4,
        accel = 4,
        handling = 2,       -- การควบคุมระดับ Standard
        hp = 120,
        stamina = 120
    },
    -- เพิ่มสายพันธุ์อื่นๆ ได้ตามชื่อใน config/horses.lua
}