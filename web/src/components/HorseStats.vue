<template>
  <div class="stats-container">
    <div class="stats-grid">
      <div class="stat-row" v-for="(val, label) in displayStats" :key="label">
        <div class="stat-info">
          <span class="stat-label">{{ label }}</span>
          <span class="stat-value">{{ val }}<span class="stat-max">/10</span></span>
        </div>
        <div class="stat-bar-bg">
          <div 
            class="stat-bar-fill" 
            :class="getBarClass(val)"
            :style="{ width: (val * 10) + '%' }"
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
      // ตรวจสอบข้อมูลก่อนแสดงผล
      const s = this.stats || {};
      return {
        "Health": s.health || 0,
        "Stamina": s.stamina || 0,
        "Speed": s.speed || 0,
        "Accel": s.acceleration || 0,
        "Agility": s.agility || 0,
        "Courage": s.courage || 0
      };
    }
  },
  methods: {
    getBarClass(val) {
      if (val >= 9) return 'bar-elite';
      if (val >= 6) return 'bar-good';
      return 'bar-normal';
    }
  }
};
</script>

<style scoped>
.stats-container {
  width: 93%;
  margin: 5px auto 10px auto;
  padding: 8px;
  background: rgba(0, 0, 0, 0.25);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 4px;
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr; /* แบ่ง 2 คอลัมน์ ซ้าย-ขวา */
  column-gap: 20px;
  row-gap: 8px;
}

.stat-row {
  display: flex;
  flex-direction: column;
}

.stat-info {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 2px;
  font-family: "robotoslab", serif; /* ใช้ฟอนต์เดียวกับธีมหลัก */
}

.stat-label {
  font-size: 13px;
  color: #d0d0d0;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: 14px;
  color: #fff;
  font-weight: bold;
}

.stat-max {
  font-size: 10px;
  color: #888;
  font-weight: normal;
}

.stat-bar-bg {
  height: 6px;
  background: rgba(30, 30, 30, 0.6);
  border-radius: 3px;
  overflow: hidden;
  box-shadow: inset 0 1px 3px rgba(0,0,0,0.5);
  border: 1px solid rgba(255,255,255,0.05);
}

.stat-bar-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.6s ease-out;
  box-shadow: 1px 0 2px rgba(0,0,0,0.3);
}

/* ธีมสีหลอดพลัง */
.bar-normal {
  background: linear-gradient(90deg, #757575, #9e9e9e); /* สีเทา */
}
.bar-good {
  background: linear-gradient(90deg, #c49a2a, #ffd700); /* สีทอง */
}
.bar-elite {
  background: linear-gradient(90deg, #8e44ad, #d2a3e6); /* สีม่วง */
}
</style>