import { createStore } from "vuex";

export default createStore({
  state: {
    visible: false,          // สถานะเปิด/ปิดเมนู
    location: "Stable",      // ชื่อสถานที่
    compData: {},
    // ข้อมูลหลัก
    myHorses: [],           // รายการม้าของฉัน
    shopHorses: [],         // รายการม้าในร้าน (แยกตาม Breed)
    
    // สถานะการเลือก
    currentTab: "owned",    // 'owned' (ม้าฉัน) หรือ 'shop' (ร้านค้า)
    selectedHorse: null,    // ม้าที่กำลังคลิกดูอยู่
    
    // ค่าเงินและ config อื่นๆ
    currencyType: 0,
    translations: {}
  },
  mutations: {
    SET_VISIBLE(state, payload) {
      state.visible = payload;
    },
    SET_DASHBOARD_DATA(state, data) {
      state.location = data.location;
      state.myHorses = data.myHorses || [];
      state.shopHorses = data.shopHorses || [];
      state.currencyType = data.currencyType;
      state.translations = data.translations || {};
      state.compData = data.compData || {};
      
      // Reset การเลือกเมื่อเปิดใหม่
      state.selectedHorse = null;
      state.currentTab = "owned";
    },
    SET_TAB(state, tab) {
      state.currentTab = tab;
      state.selectedHorse = null; // เปลี่ยนแท็บแล้วล้างการเลือก
    },
    SET_SELECTED_HORSE(state, horse) {
      state.selectedHorse = horse;
    }
  },
  actions: {
    openDashboard({ commit }, data) {
      commit("SET_DASHBOARD_DATA", data);
      commit("SET_VISIBLE", true);
    },
    closeDashboard({ commit }) {
      commit("SET_VISIBLE", false);
    },
    selectTab({ commit }, tab) {
      commit("SET_TAB", tab);
    },
    selectHorse({ commit }, horse) {
      commit("SET_SELECTED_HORSE", horse);
    }
  },
  getters: {
    // ดึงรายการม้าตามแท็บที่เลือก
    currentList: (state) => {
      if (state.currentTab === 'owned') {
        return state.myHorses;
      } else {
        // สำหรับร้านค้า เราอาจจะต้องแปลง structure นิดหน่อยถ้า Lua ส่งมาซับซ้อน
        // แต่ถ้า Lua ส่งมาเป็น List ของ Breed ก็ใช้ได้เลย
        return state.shopHorses;
      }
    },
    _U: (state) => (key) => {
      return state.translations[key] || key;
    }
  }
});