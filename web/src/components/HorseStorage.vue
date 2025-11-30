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
              <span class="val-current">{{ count }}</span>
              <span class="val-divider">/</span>
              <span class="val-max">{{ limit }}</span>
              <span class="val-unit">ช่อง</span>
           </div>
        </div>

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

/* หัวข้อ - Saddle Bags (สีทอง Gradient เดิม) */
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

/* เส้นขีด - สีทอง */
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
  gap: 6px; /* ระยะห่างระหว่างคำ */
}

/* Class พิเศษสำหรับจัดกึ่งกลาง */
.center-align {
  justify-content: center;
  width: 100%;
}

/* ข้อมูล: จำนวน ... ช่อง (สีขาวทั้งหมด) */
.val-label, .val-current, .val-divider, .val-max, .val-unit {
  font-size: 20px;
  font-weight: 500;
  color: #ffffff; /* สีขาว */
}

.val-unit {
  font-size: 18px; /* หน่วยเล็กกว่านิดหน่อย */
}
</style>