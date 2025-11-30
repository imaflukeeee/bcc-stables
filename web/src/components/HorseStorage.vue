<template>
  <div class="stats-container-large">
    <div class="stats-header">
      <h2>Saddle Bags</h2>
      <div class="header-line"></div>
    </div>
    
    <div class="stats-list">
      <div class="stat-item">
        
        <div class="stat-top-row">
           <div class="stat-numbers-wrapper center-align">
              <span class="val-label">จำนวน</span>
              <span class="val-max">{{ limit }}</span>
              <span class="val-unit">ช่อง</span>
           </div>
        </div>

        <button v-if="showActionBtn" class="action-button-small" @click="openCargo">
          เปิดกระเป๋า
        </button>

      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "HorseStorage",
  props: {
    limit: {
      type: [Number, String],
      default: 0
    },
    count: {
      type: [Number, String],
      default: 0
    },
    // เพิ่ม Prop ใหม่สำหรับซ่อน/แสดงปุ่ม (ค่าเริ่มต้นเป็น true คือแสดงปกติ)
    showActionBtn: {
      type: Boolean,
      default: true
    }
  },
  methods: {
      openCargo() {
          this.$emit('open-cargo');
      }
  }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Pridi:wght@300;400;500;600;700&display=swap');

/* คอนเทนเนอร์หลัก */
.stats-container-large {
  width: 100%;
  padding: 0;
  background: transparent;
  border: none;
  box-shadow: none;
  font-family: 'Pridi', serif;
}

/* หัวข้อ - Saddle Bags */
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
  color: #f1c40f;
  text-shadow: none;
}

/* เส้นขีด */
.header-line {
  width: 70px;
  height: 3px;
  background: #ffffff;
  margin: 10px auto 22px auto;
  border-radius: 2px;
}

.stats-list {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
  align-items: center;
}

.stat-top-row {
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 2px;
}

.stat-numbers-wrapper {
  display: flex;
  align-items: baseline;
  font-family: 'Pridi', serif;
  gap: 6px;
}

.center-align {
  justify-content: center;
  width: 100%;
}

.val-label, .val-current, .val-divider, .val-max, .val-unit {
  font-size: 20px;
  font-weight: 500;
  color: #ffffff;
}

.val-unit {
  font-size: 18px;
}

.action-button-small {
    padding: 8px 25px;
    background: #d4af37;
    color: #111;
    border: none;
    border-radius: 20px;
    font-size: 14px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    cursor: pointer;
    transition: background 0.2s, transform 0.2s;
    margin-top: 10px; 
    box-shadow: 0 4px 10px rgba(0, 0, 0, 0.4);
}

.action-button-small:hover {
    background: #f1c40f;
    transform: translateY(-1px);
}
</style>