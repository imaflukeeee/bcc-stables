<template>
  <div class="stats-container-large">
    <div class="stats-header">
      <h2>HORSE INFO</h2>
      <div class="header-line"></div>
    </div>
    
    <div class="stats-list">
      <div class="stat-item" v-for="(val, label) in displayStats" :key="label">
        
        <div class="stat-top-row">
           <div class="stat-label-group">
              <img :src="getIcon(label)" class="stat-icon-img" alt="icon" />
              <span class="stat-name">{{ label }}</span>
           </div>
           
           <div class="stat-numbers-wrapper">
              <span class="val-current">{{ val }}</span>
              <span class="val-divider">/</span>
              <span class="val-max">10</span>
           </div>
        </div>

        <div class="stat-dashed-bar">
           <div 
             v-for="n in 10" 
             :key="n" 
             class="dash-segment"
             :class="{ active: n <= val }"
           ></div>
        </div>

      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "HorseStats",
  props: {
    stats: {
      type: Object,
      default: () => ({})
    }
  },
  computed: {
    displayStats() {
      const s = this.stats || {};
      return {
        "พลังชีวิต": s.health || 0,
        "สเติมิน่า": s.stamina || 0,
        "ความเร็ว": s.speed || 0,
        "อัตราเร่ง": s.acceleration || 0,
        "ความคล่องตัว": s.agility || 0,
        "ความกล้าหาญ": s.courage || 0
      };
    }
  },
  methods: {
    getIcon(label) {
      try {
        switch(label) {
          case 'พลังชีวิต': return require('@/assets/img/icon-stats-horse/horse_health.png');
          case 'สเติมิน่า': return require('@/assets/img/icon-stats-horse/horse_stamina.png');
          case 'ความเร็ว': return require('@/assets/img/icon-stats-horse/horse_speed.png');
          case 'อัตราเร่ง': return require('@/assets/img/icon-stats-horse/horse_accel.png');
          case 'ความคล่องตัว': return require('@/assets/img/icon-stats-horse/horse_agi.png');
          case 'ความกล้าหาญ': return require('@/assets/img/icon-stats-horse/horse_shield.png');
          default: return ''; 
        }
      } catch (e) {
        console.error("Icon not found for:", label);
        return '';
      }
    }
  }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Pridi:wght@300;400;500;600;700&display=swap');

/* คอนเทนเนอร์หลัก - ลบพื้นหลังและขอบออก */
.stats-container-large {
  width: 100%;
  padding: 0; /* ลบ padding ออกเพื่อให้ชิดขอบหรือจัดวางตาม layout ภายนอก */
  background: transparent; /* พื้นหลังโปร่งใส */
  border: none; /* ไม่มีเส้นขอบ */
  box-shadow: none; /* ไม่มีเงา */
  font-family: 'Pridi', serif;
}

/* หัวข้อ */
.stats-header h2 {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 2px;
  text-align: center;
  background: linear-gradient(to bottom, #f1c40f, #b7950b);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  color: #f1c40f; /* Fallback */
  text-shadow: none; 
}

.header-line {
  width: 70px;
  height: 3px;
  background: #ffffff;
  margin: 10px auto 22px auto;
  border-radius: 2px;
}

/* รายการ Stats */
.stats-list {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

/* แถวบน: ไอคอน ชื่อ ค่าพลัง */
.stat-top-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2px;
}

.stat-label-group {
  display: flex;
  align-items: center;
  gap: 4px;
}

/* รูปไอคอน */
.stat-icon-img {
  width: 14px;
  height: 14px;
  object-fit: contain;
  filter: brightness(0) invert(1) drop-shadow(0 0 2px rgba(255,255,255,0.4)); 
}

/* ชื่อค่าพลัง */
.stat-name {
  color: #ffffff;
  font-size: 16px;
  font-weight: 400;
  text-transform: uppercase;
  letter-spacing: 1px;
  text-shadow: 0 0 4px rgba(0,0,0,0.5);
}

/* Wrapper สำหรับตัวเลข */
.stat-numbers-wrapper {
  display: flex;
  align-items: baseline;
  font-family: 'Pridi', serif;
}

/* ตัวเลขค่าปัจจุบัน */
.val-current {
  color: #ffffff;
  font-size: 16px;
  font-weight: 500;
}

/* เครื่องหมาย / */
.val-divider {
  color: #888888;
  font-size: 16px;
  font-weight: 500;
  margin: 0 2px;
}

/* ตัวเลขเต็ม (10) */
.val-max {
  color: #888888;
  font-size: 16px;
  font-weight: 500;
}

/* ส่วนหลอดขีดๆ */
.stat-dashed-bar {
  display: flex;
  width: 100%;
  height: 10px;
  gap: 4px;
}

.dash-segment {
  flex: 1;
  background: rgba(0, 0, 0, 0.5); /* สีดำโปร่งแสงสำหรับช่องว่าง */
  border-radius: 3px;
  transition: all 0.3s ease;
}

/* สีเมื่อ Active */
.dash-segment.active {
  background: #ffffff;
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: none;
}
</style>