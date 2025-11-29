<template>
  <div class="panel-shop item flex" @click="loadHorse()">
    <div class="item flex flex-auto">
      <h6 class="grey-text-shop title">
        {{ horse.color }}
      </h6>
    </div>

    <div class="buy-buttons flex flex-auto justify-end">
      
      <button
        v-if="horse.cashPrice && horse.cashPrice > 0"
        style="display: flex; justify-content: flex-start"
        class="btn-small mr"
        @click="showModal('cash')"
      >
        <img src="../assets/img/money.png" class="ml-1" />
        <span class="ml-1">{{ horse.cashPrice }}</span>
      </button>

      <button
        v-if="horse.goldPrice && horse.goldPrice > 0"
        style="display: flex; justify-content: flex-start"
        class="btn-small mr"
        @click="showModal('gold')"
      >
        <img src="../assets/img/gold.png" class="ml-1" />
        <span class="ml-1">{{ horse.goldPrice }}</span>
      </button>

      <button
        v-if="horse.itemPrice && horse.itemPrice.amount > 0"
        style="display: flex; justify-content: flex-start"
        class="btn-small right-btn"
        @click="showModal('item')"
      >
        <img src="../assets/img/toast.png" class="ml-1" style="width: 20px; height: 20px;" /> 
        <span class="ml-1">{{ horse.itemPrice.amount }} {{ horse.itemPrice.label }}</span>
      </button>

    </div>
  </div>

  <ConfirmationModal :visible="isVisible" title="Purchase" @close="hideModal()">
    <div class="divider-menu-top" style="margin-top: 1rem"></div>
    <div class="flex cta-wrapper">
      <button @click="buyHorse()" class="modal-btn flex flex-auto">
        Confirm
      </button>
      <button @click="hideModal" class="modal-btn flex flex-auto">
        Cancel
      </button>
    </div>
    <div class="divider-menu-bottom"></div>
  </ConfirmationModal>

  <ConfirmationModal
    :visible="genderVisible"
    title="Select Gender"
    @close="hideGenderModal()"
  >
    <div class="divider-menu-top" style="margin-top: 1rem"></div>
    <div class="flex cta-wrapper">
      <button @click="setGender('male')" class="modal-btn flex flex-auto">
        Male
      </button>
      <button @click="setGender('female')" class="modal-btn flex flex-auto">
        Female
      </button>
      <button @click="hideGenderModal" class="modal-btn flex flex-auto">
        Cancel
      </button>
    </div>
    <div class="divider-menu-bottom"></div>
  </ConfirmationModal>
</template>

<script>
import api from "@/api";
import { mapState } from "vuex";
import ConfirmationModal from "./ConfirmationModal.vue";

export default {
  name: "TraderMenuColor",
  props: {
    horse: Object,
    model: String,
  },
  data() {
    return {
      isVisible: false,
      genderVisible: false,
      selectedCurrency: null, // เปลี่ยนจาก curType (boolean) เป็น string ('cash', 'gold', 'item')
      gender: "male",
    };
  },
  computed: {
    ...mapState(["activeHorse"]),
  },
  methods: {
    showModal(currency) {
      this.selectedCurrency = currency;
      this.genderVisible = true;
    },
    hideModal() {
      this.selectedCurrency = null;
      this.isVisible = false;
    },
    hideGenderModal() {
      this.selectedCurrency = null;
      this.genderVisible = false;
    },
    setGender(gender) {
      this.gender = gender;
      this.genderVisible = false;
      this.isVisible = true;
    },
    loadHorse() {
      if (this.activeHorse) {
        this.$store.dispatch("setSelectedHorse", null);
      }
      api.post("loadHorse", {
        horseModel: this.model,
      });
    },
    buyHorse() {
      if (this.selectedCurrency !== null) {
        api.post("BuyHorse", {
          ModelH: this.model,
          currencyType: this.selectedCurrency, // ส่งค่าประเภทสกุลเงินไปแทน IsCash
          gender: this.gender,
        });
      }

      this.isVisible = false;
      this.genderVisible = false;
      this.selectedCurrency = null;
      this.gender = "male";
    },
  },
  components: {
    ConfirmationModal,
  },
};
</script>

<style scoped lang="scss">
/* (CSS เดิมทั้งหมด ไม่ต้องแก้ไข) */
.flex { display: flex; }
.flex-auto { flex: 1 1 auto; }
.justify-end { justify-content: flex-end; }
.ml-1 { margin-left: 0.25rem; }
.mr { margin-right: 1rem; }
.item { margin-left: 25px; }
.panel-shop.item {
  padding: 5px 0px;
  margin: 3px 10px;
  width: calc(100% - 20px);
  background-color: transparent;
  overflow: hidden;
  background-image: url("../assets/img/input.png"), url("../assets/img/input.png");
  background-size: 100% 100%;
  background-repeat: no-repeat;
  background-position: center;
}
.panel-shop.item:hover, .panel-shop.item.active {
  background-image: url("../assets/img/selected.png"), url("../assets/img/selection_box.png");
}
.grey-text-shop.title { color: #9e9e9e; text-align: left; margin: auto 0; font-size: 1em; }
.buy-buttons { display: flex; background: transparent; }
.btn-small {
  display: flex; flex-direction: row; justify-content: center; align-items: center;
  text-decoration: none; color: #f0f0f0; user-select: none; text-align: left;
  min-width: 75px; /* ปรับ width เป็น min-width เพื่อให้ยืดตามชื่อไอเทมได้ */
  padding: 0 5px;
  letter-spacing: 0.5px; transition: background-color 0.2s ease-out;
  border: 0px #fff solid; background: transparent;
}
.btn-small:hover {
  background: url("../assets/img/buttonv.png"); background-size: 90% 100%;
  background-repeat: no-repeat; background-position: right;
}
.btn-small.right-btn { margin-right: 5px; }
.cta-wrapper { background: url("../assets/img/input.png"); background-size: 100% 100%; height: 4vh; }
.modal-btn {
  flex-direction: row; justify-content: center; align-items: center; text-decoration: none;
  color: #f0f0f0; user-select: none; text-align: left; width: 75px; letter-spacing: 0.5px;
  border: 0px #fff solid;
}
.modal-btn:hover {
  background: url("../assets/img/buttonv.png"); background-size: 90% 100%;
  background-repeat: no-repeat; background-position: right;
}
.divider-menu-top, .divider-menu-bottom {
  width: 90%; height: 4px; margin: auto auto;
  background-image: url("../assets/img/divider_line.png"); background-size: 100% 100%; opacity: 0.6;
}
.divider-menu-top { margin-bottom: 10px; }
.divider-menu-bottom { margin-top: 10px; }
</style>