<template>
  <div id="app">
    <Dashboard v-if="visible" />
  </div>
</template>

<script>
import { mapState } from "vuex";
import Dashboard from "./views/Dashboard.vue"; // นำเข้าหน้าใหม่

export default {
  name: "App",
  components: {
    Dashboard
  },
  computed: {
    ...mapState(["visible"])
  },
  mounted() {
    // ดักฟัง NUI Event จาก Lua
    window.addEventListener("message", this.onMessage);
  },
  unmounted() {
    window.removeEventListener("message", this.onMessage);
  },
  methods: {
    onMessage(event) {
      const item = event.data;
      
      // ถ้าได้รับคำสั่ง OPEN_DASHBOARD
      if (item.action === "OPEN_DASHBOARD") {
        // ส่งข้อมูลเข้า Store
        this.$store.dispatch("openDashboard", item.data);
      }
      
      // คำสั่งปิด
      if (item.action === "hide") {
        this.$store.dispatch("closeDashboard");
      }
    }
  }
};
</script>

<style>
/* Reset Global Style */
body {
  margin: 0;
  padding: 0;
  overflow: hidden;
  user-select: none;
}
#app {
  width: 100vw;
  height: 100vh;
}
</style>