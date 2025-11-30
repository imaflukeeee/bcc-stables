<template>
  <div class="modal-wrapper" v-if="visible">
    <div class="modal-overlay" @click="close"></div>
    <div class="modal-container">
      <div class="modal-header">
        <h3 class="modal-title">{{ title }}</h3>
      </div>
      <div class="modal-content">
        <slot></slot>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "ConfirmationModal",
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      default: "Confirmation",
    },
  },
  methods: {
    close() {
      // สามารถเลือกได้ว่าจะให้คลิกพื้นหลังแล้วปิดหรือไม่
      // this.$emit("close");
    },
  },
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Pridi:wght@300;400;500;600;700&display=swap');

.modal-wrapper {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 9999;
  display: flex;
  justify-content: center;
  align-items: center;
}

.modal-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.7); /* พื้นหลังดำจางๆ เข้มขึ้น */
  z-index: -1;
}

.modal-container {
  position: relative;
  width: 400px; /* ความกว้างคงที่ที่เหมาะสม */
  max-width: 90%;
  background: rgba(20, 20, 20, 0.664); /* พื้นหลังสีดำด้าน Flat */
  border: 1px solid rgba(255, 255, 255, 0.1); /* เส้นขอบบางๆ */
  border-radius: 6px;
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.5); /* เงาให้ดูลอยขึ้นมา */
  display: flex;
  flex-direction: column;
  overflow: hidden;
  font-family: 'Pridi', serif; /* ใช้ฟอนต์เดียวกับ Dashboard */
  animation: fadeIn 0.2s ease-out;
}

.modal-header {
  padding: 15px 20px;
  background: rgba(255, 255, 255, 0.03); /* สีพื้นหลังหัวข้อจางๆ */
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  text-align: center;
}

.modal-title {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #fff;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.modal-content {
  padding: 30px 25px;
  color: #e0e0e0;
  font-size: 14px;
  font-weight: 300;
  line-height: 1.6;
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.95); }
  to { opacity: 1; transform: scale(1); }
}
</style>