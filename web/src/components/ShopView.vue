<template>
  <div class="shop-view-container">
    
    <button v-if="selectedHorse" class="floating-back-btn" @click="clearSelection">
      <i class="fas fa-chevron-left"></i> BACK TO LIST
    </button>

    <div v-if="!selectedHorse" class="shop-list-header">
        <h1>ตลาดซื้อ - ขายม้า</h1>
        <p>โปรดเลือกม้าสายพันธุ์ที่คุณต้องการ</p>
    </div>

    <div v-if="!selectedHorse" class="carousel-wrapper">
        
        <button class="carousel-arrow left" @click="prevItem">❮</button>

        <div class="carousel-track-container">
            <div class="carousel-track" :style="trackStyle">
                <div 
                    v-for="(horse, index) in horses" 
                    :key="index"
                    class="showroom-card-carousel"
                    :class="{ 'active': index === focusedIndex }"
                    @click="setFocusAndSelect(index)"
                >
                    <div class="card-center-icon">
                        <img src="@/assets/img/buy-horse-icon.png" class="white-icon-medium" />
                    </div>
                    <div class="card-body">
                        <h3 class="horse-name-show">{{ horse.breed || horse.model }}</h3>
                        <p class="horse-breed-show" v-if="horse.colors">
                            Start ${{ getStartPrice(horse) }}
                        </p>
                    </div>
                    <div class="selection-border" v-if="index === focusedIndex"></div>
                </div>
            </div>
        </div>

        <button class="carousel-arrow right" @click="nextItem">❯</button>

        <div class="key-hint">
             <span>กดลูกศรซ้าย - ขวาเพื่อเลื่อนและกด [ENTER] เพื่อเลือก</span>
        </div>
    </div>


    <div v-else class="manage-action-view">
        <div class="selected-horse-header">
            <h1 style="min-height: 1.2em;">{{ currentShopColorData?.color || selectedHorse.breed }}</h1>
            <div class="sub-info">
                <span>{{ selectedHorse.gender || 'Stallion' }}</span> • 
                <span>{{ selectedHorse.breed || selectedHorse.model }}</span>
            </div>
        </div>

        <div class="manage-stats-wrapper">
            <HorseStats :stats="selectedHorse.stats || {}" />
        </div>

        <div class="manage-info-right">
            <HorseStorage 
                :limit="currentShopColorData?.invLimit || 0" 
                :show-action-btn="false" 
            />
        </div>

        <div class="shop-controls-center">
            <div class="color-selector-row" v-if="shopColorList.length > 1">
                <button class="nav-arrow arrow-fixed-left" @click="prevColor">❮</button>
                <div class="color-info-wrapper">
                    <span class="color-label">COLOR VARIANT</span>
                    <span class="color-name">{{ currentShopColorData?.color }}</span>
                </div>
                <button class="nav-arrow arrow-fixed-right" @click="nextColor">❯</button>
            </div>

            <div class="name-input-wrapper">
                <input type="text" v-model="newHorseName" placeholder="ตั้งชื่อม้าของคุณ..." class="shop-input" maxlength="20" ref="nameInput" />
            </div>

            <div class="buy-actions-row" v-if="currentShopColorData">
                <button v-if="currentShopColorData.cashPrice > 0" class="buy-btn btn-cash" :disabled="!newHorseName" @click="buy('cash')">
                    <span class="currency-symbol">$</span> {{ currentShopColorData.cashPrice }}
                </button>
                <button v-if="currentShopColorData.goldPrice > 0" class="buy-btn btn-gold" :disabled="!newHorseName" @click="buy('gold')">
                    <img src="@/assets/img/gold.png" class="currency-icon"/> {{ currentShopColorData.goldPrice }} Gold
                </button>
                <button v-if="currentShopColorData.itemPrice?.amount > 0" class="buy-btn btn-item" :disabled="!newHorseName" @click="buy('item')">
                    <img src="@/assets/img/toast.png" class="currency-icon"/> {{ currentShopColorData.itemPrice.amount }} {{ currentShopColorData.itemPrice.label || 'Token' }}
                </button>
            </div>
        </div>
    </div>

  </div>
</template>

<script>
import { mapState } from 'vuex';
import api from '@/api';
import HorseStats from './HorseStats.vue';
import HorseStorage from './HorseStorage.vue';

export default {
  name: "ShopView",
  components: { HorseStats, HorseStorage },
  data() {
    return {
      currentColorIndex: 0,
      newHorseName: "",
      focusedIndex: 0, 
    }
  },
  computed: {
    ...mapState(['shopHorses', 'selectedHorse']),
    
    horses() {
        return this.shopHorses || [];
    },

    // [สูตรใหม่] แม่นยำ 100%
    trackStyle() {
        // ขนาดต้องตรงกับ CSS
        const cardWidth = 200; 
        const gap = 20;        
        const centerOffset = cardWidth / 2; // 100px (ครึ่งการ์ด)
        
        // คำนวณระยะที่ต้องถอยหลัง
        // (จำนวนตัวก่อนหน้า * ความกว้างรวม) + ครึ่งตัวของตัวปัจจุบัน
        const shiftAmount = (this.focusedIndex * (cardWidth + gap)) + centerOffset;
        
        return {
            // เลื่อนไปซ้าย (ติดลบ) เพื่อดึงตัวที่เลือกกลับมาตรงกลาง (ซึ่งอยู่ที่ left: 50%)
            transform: `translateX(-${shiftAmount}px)`
        };
    },
    
    shopColorList() {
        if (!this.selectedHorse || !this.selectedHorse.colors) return [];
        return Object.entries(this.selectedHorse.colors).map(([model, data]) => ({
            model: model,
            ...data
        }));
    },
    
    currentShopColorData() {
        if (this.shopColorList.length === 0) return null;
        return this.shopColorList[this.currentColorIndex];
    }
  },
  
  mounted() {
      window.addEventListener('keydown', this.handleKeydown);
      // โฟกัสตัวแรกเสมอเมื่อเริ่ม
      if (this.horses.length > 0) this.onHover(this.horses[0]);
  },
  beforeUnmount() {
      window.removeEventListener('keydown', this.handleKeydown);
  },

  watch: {
    selectedHorse(newVal) {
        if (newVal) {
            this.currentColorIndex = 0;
            this.updatePreview();
            this.newHorseName = "";
            this.$nextTick(() => { if(this.$refs.nameInput) this.$refs.nameInput.focus(); });
        }
    },
    horses(newVal) {
        if (newVal && newVal.length > 0) {
            this.focusedIndex = 0;
            this.onHover(newVal[0]);
        }
    }
  },
  methods: {
    // จัดการ Keyboard
    handleKeydown(e) {
        if (!this.selectedHorse) {
            if (e.key === 'ArrowLeft') this.prevItem();
            else if (e.key === 'ArrowRight') this.nextItem();
            else if (e.key === 'Enter') this.selectFocusedCategory();
        } else {
             if (e.key === 'ArrowLeft' && document.activeElement !== this.$refs.nameInput) this.prevColor();
             else if (e.key === 'ArrowRight' && document.activeElement !== this.$refs.nameInput) this.nextColor();
             else if (e.key === 'Escape') this.clearSelection();
        }
    },

    // Carousel Logic
    prevItem() {
        if (this.focusedIndex > 0) {
            this.focusedIndex--;
            this.onHover(this.horses[this.focusedIndex]);
        }
    },
    nextItem() {
        if (this.focusedIndex < this.horses.length - 1) {
            this.focusedIndex++;
            this.onHover(this.horses[this.focusedIndex]);
        }
    },
    setFocusAndSelect(index) {
        this.focusedIndex = index;
        // คลิกแล้วเลือกเลย (ตาม UX ทั่วไป) หรือจะแค่ Focus ก็ได้ แต่เลือกเลยจะไวกว่า
        this.selectFocusedCategory(); 
    },
    selectFocusedCategory() {
        const horse = this.horses[this.focusedIndex];
        if (horse) this.selectHorse(horse);
    },

    getStartPrice(horse) {
        if (!horse.colors) return 0;
        return Object.values(horse.colors)[0].cashPrice || 0;
    },
    selectHorse(horse) {
        this.$store.dispatch('selectHorse', horse);
    },
    clearSelection() {
        this.$store.dispatch('selectHorse', null);
        api.post("loadHorse", { horseModel: 'CLEAR' });
        // คืนค่า Preview ตัวที่เลือกค้างไว้
        setTimeout(() => {
             if (this.horses[this.focusedIndex]) this.onHover(this.horses[this.focusedIndex]);
        }, 200);
    },
    onHover(horse) {
        if (horse && horse.colors) {
            const firstModel = Object.keys(horse.colors)[0];
            api.post("loadHorse", { horseModel: firstModel });
        }
    },
    nextColor() {
        if (this.currentColorIndex >= this.shopColorList.length - 1) this.currentColorIndex = 0;
        else this.currentColorIndex++;
        this.updatePreview();
    },
    prevColor() {
        if (this.currentColorIndex <= 0) this.currentColorIndex = this.shopColorList.length - 1;
        else this.currentColorIndex--;
        this.updatePreview();
    },
    updatePreview() {
        if (this.currentShopColorData) {
            api.post("loadHorse", { horseModel: this.currentShopColorData.model });
        }
    },
    buy(currency) {
        if (!this.currentShopColorData || !this.newHorseName) return;
        api.post("BuyHorse", { 
            ModelH: this.currentShopColorData.model, 
            name: this.newHorseName, 
            currencyType: currency, 
            isTrainer: false 
        });
        this.$emit('close-menu');
    }
  }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Pridi:wght@300;400;500;600;700&display=swap');
* { font-family: 'Pridi', serif !important; }

.shop-view-container {
    width: 100%; height: 100%;
    position: absolute; top: 0; left: 0;
}

/* ================== CAROUSEL STYLE (แก้ไข) ================== */
.carousel-wrapper {
    position: absolute; bottom: 40px; left: 0; width: 100%;
    display: flex; flex-direction: column; align-items: center;
    z-index: 10;
}

.carousel-track-container {
    width: 100%;
    height: 220px;
    overflow: hidden; /* บังส่วนเกิน */
    position: relative;
    /* Mask ไล่เฟดหัวท้าย */
    mask-image: linear-gradient(to right, transparent 0%, black 20%, black 80%, transparent 100%);
    -webkit-mask-image: linear-gradient(to right, transparent 0%, black 20%, black 80%, transparent 100%);
}

.carousel-track {
    display: flex;
    gap: 20px; /* ต้องตรงกับ JS gap=20 */
    position: absolute; 
    left: 50%; /* จุดเริ่มที่กึ่งกลางจอ */
    top: 50%;
    transform-origin: 0 0; /* จุดหมุนเริ่มที่ซ้ายบนของตัวเอง */
    /* จัดแนวตั้งให้กลาง (ลบความสูงครึ่งนึงออก) */
    margin-top: -80px; /* ครึ่งหนึ่งของความสูงการ์ด (160/2) */
    
    transition: transform 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.showroom-card-carousel {
    width: 200px; height: 160px; /* ต้องตรงกับ JS cardWidth=200 */
    background: rgba(20, 20, 20, 0.8);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 8px;
    display: flex; flex-direction: column;
    justify-content: center; align-items: center;
    gap: 10px;
    cursor: pointer;
    flex-shrink: 0; /* ห้ามหด */
    position: relative;
    transition: all 0.3s ease;
    opacity: 0.5; transform: scale(0.9);
}

.showroom-card-carousel.active {
    opacity: 1; transform: scale(1.1);
    background: rgba(40, 40, 40, 0.95);
    border-color: #d4af37;
    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    z-index: 2;
}

.selection-border {
    position: absolute; top: -2px; left: -2px; right: -2px; bottom: -2px;
    border: 2px solid #ffffff; border-radius: 10px;
    box-shadow: 0 0 15px rgba(212, 175, 55, 0.5); pointer-events: none;
}

/* Card Content Centering */
.card-center-icon { display: flex; justify-content: center; align-items: center; width: 100%; }
.card-body { width: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; }
.horse-name-show { font-size: 16px; font-weight: 600; color: #fff; margin: 0; text-align: center; }
.horse-breed-show { font-size: 12px; color: #aaa; margin: 2px 0 0 0; text-align: center; }

/* Arrows */
.carousel-arrow {
    position: absolute; top: 50%; transform: translateY(-50%);
    background: rgba(0,0,0,0.5); border: 1px solid rgba(255,255,255,0.2);
    color: #fff; width: 60px; height: 60px; border-radius: 50%;
    font-size: 24px; cursor: pointer; z-index: 20; transition: 0.2s;
}
.carousel-arrow:hover { background: #fff; color: #000; transform: translateY(-50%) scale(1.1); }
.carousel-arrow.left { left: 10%; }
.carousel-arrow.right { right: 10%; }

.key-hint { margin-top: 10px; font-size: 14px; color: #aaa; background: rgba(0,0,0,0.6); padding: 5px 15px; border-radius: 20px; }

/* ... (CSS ส่วนอื่นๆ เหมือนเดิม) ... */
.shop-list-header { position: absolute; top: 10%; left: 0; width: 100%; text-align: center; text-shadow: 0 2px 10px rgba(0,0,0,0.8); pointer-events: none; z-index: 20; }
.shop-list-header h1 { font-size: 56px; margin: 0; color: #fff; letter-spacing: 4px; font-weight: 600; }
.shop-list-header p { font-size: 18px; color: #ddd; margin-top: 5px; font-weight: 300; }
.floating-back-btn { position: absolute; top: 40px; left: 40px; background: rgba(0,0,0,0.5); border: 1px solid rgba(255,255,255,0.2); color: #fff; padding: 10px 20px; border-radius: 30px; cursor: pointer; z-index: 100; transition: 0.3s; font-weight: 600; }
.floating-back-btn:hover { background: #fff; color: #000; }
.white-icon-medium { width: 50px; height: 50px; filter: brightness(0) invert(1); opacity: 0.9; }
.manage-action-view { position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; background: linear-gradient(to top, rgba(0,0,0,0.9) 0%, transparent 60%); z-index: 5; }
.selected-horse-header { position: absolute; top: 5%; left: 0; width: 100%; text-align: center; pointer-events: none; }
.selected-horse-header h1 { font-size: 48px; margin: 0; color: #fff; letter-spacing: 2px; }
.sub-info { font-size: 16px; color: #ccc; }
.manage-stats-wrapper { position: absolute; top: 45%; left: 80px; transform: translateY(-50%); width: 300px; z-index: 20; }
.manage-info-right { position: absolute; top: 45%; right: 80px; transform: translateY(-50%); width: 300px; z-index: 20; }
.shop-controls-center { position: absolute; bottom: 50px; left: 50%; transform: translateX(-50%); display: flex; flex-direction: column; align-items: center; gap: 20px; width: 100%; z-index: 20; }
.color-selector-row { display: flex; align-items: center; justify-content: space-between; width: 400px; height: 50px; position: relative; }
.nav-arrow { background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); color: #fff; width: 45px; height: 45px; border-radius: 50%; cursor: pointer; font-size: 18px; display: flex; align-items: center; justify-content: center; transition: 0.2s; }
.nav-arrow:hover { background: #fff; color: #000; }
.arrow-fixed-left { position: absolute; left: 0; top: 50%; transform: translateY(-50%); }
.arrow-fixed-right { position: absolute; right: 0; top: 50%; transform: translateY(-50%); }
.color-info-wrapper { flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; overflow: hidden; padding: 0 50px; }
.color-label { font-size: 10px; color: #888; letter-spacing: 2px; }
.color-name { font-size: 24px; font-weight: 600; color: #fff; white-space: nowrap; }
.name-input-wrapper { width: 300px; }
.shop-input { width: 100%; padding: 12px; background: rgba(0,0,0,0.5); border: 1px solid rgba(255,255,255,0.3); color: #fff; text-align: center; font-size: 16px; border-radius: 4px; }
.shop-input:focus { border-color: #d4af37; outline: none; background: rgba(0,0,0,0.7); }
.buy-actions-row { display: flex; gap: 15px; justify-content: center; }
.buy-btn { padding: 12px 25px; border: none; border-radius: 4px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; font-size: 14px; transition: transform 0.2s; }
.buy-btn:hover { transform: translateY(-3px); }
.buy-btn:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }
.currency-icon { width: 20px; height: 20px; }
.currency-symbol { font-size: 18px; font-weight: 700; color: #111; margin-right: 2px; }
.btn-cash { background: #fff; color: #000; }
.btn-gold { background: #DAA520; color: #000; }
.btn-item { background: #333; color: #fff; border: 1px solid #555; }
</style>