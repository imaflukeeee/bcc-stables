const { defineConfig } = require('@vue/cli-service')

module.exports = defineConfig({
  transpileDependencies: true,
  
  // ให้ Path เป็น Relative เพื่อให้ FiveM อ่านไฟล์ถูก
  publicPath: "./",
  
  // [ส่วนที่เพิ่ม] สั่งให้ Build ออกไปที่โฟลเดอร์ ui ที่อยู่ข้างนอก (ถอยหลัง 1 ชั้น ../ แล้วเข้า ui)
  outputDir: '../ui',

  // (แนะนำเพิ่มเติม) ปิดการสร้างไฟล์ .map เพื่อลดขนาดไฟล์และจำนวนไฟล์ในโฟลเดอร์ ui
  productionSourceMap: false,
})