<template>
  <div class="dashboard-container">
    
    <div v-if="viewMode === 'home'" class="home-menu">
      <div class="showroom-header">
        <h1>{{ location }}</h1>
        <p>เลือกตัวเลือกเพื่อดำเนินต่อ</p>
      </div>

      <div class="menu-grid">
        <div class="menu-card" @click="enterMode('owned')">
          <div class="card-content">
            <div class="big-icon">
                <img src="@/assets/img/head-horse-icon.png" alt="Manage Stable" class="white-icon" />
            </div>
            <h2>ดูแลและจัดการคอกม้า</h2>
            <p>ตรวจเช็กม้าคู่หูของคุณแล้วจัดการดูแลให้พร้อมเดินทาง</p>
          </div>
        </div>

        <div class="menu-card" @click="enterMode('shop')">
          <div class="card-content">
            <div class="big-icon">
                <img src="@/assets/img/buy-horse-icon.png" alt="Buy Horse" class="white-icon" />
            </div>
            <h2>เลือกซื้อม้าตัวใหม่</h2>
            <p>ซื้อม้าชั้นเยี่ยมตัวใหม่เข้าฝูง</p>
          </div>
        </div>
      </div>
      
      <button class="close-btn-home" @click="closeMenu">ออกจากที่นี่</button>
    </div>


    <div v-else class="content-view">
      
      <button v-if="currentTab === 'owned' && subMode !== 'list'" class="floating-back-btn" @click="handleBack">
        <i class="fas fa-chevron-left"></i> {{ getBackLabel() }}
      </button>
      <button v-if="currentTab === 'owned' && subMode === 'list'" class="floating-back-btn" @click="goHome">
        <i class="fas fa-chevron-left"></i> HOME
      </button>

      <template v-if="currentTab === 'owned'">
        
        <div v-if="currentList.length === 0" class="empty-state-view">
            <div class="empty-content">
                <div class="big-icon">
                    <img src="@/assets/img/head-horse-icon.png" class="white-icon" style="opacity: 0.5;" />
                </div>
                <h2>คอกว่าง… ไม่มีม้าให้พบเห็น</h2>
                <p>คุณยังไม่มีม้าคู่ใจไว้ใช้งานเลยสักตัว</p>
                <button class="action-btn btn-white" style="margin-top: 20px; width: auto; padding: 10px 40px;" @click="goToShop">
                    ตลาดม้า
                </button>
            </div>
        </div>

        <template v-else>
            
            <div v-if="subMode === 'list' && hoveredHorse" class="hover-preview-container">
                <div class="manage-stats-wrapper">
                    <HorseStats :stats="hoveredHorse.stats || {}" />
                </div>
                <div class="manage-info-right">
                    <HorseStorage :limit="hoveredHorse.invLimit || 0" :show-action-btn="false" />
                </div>
            </div>

            <div v-if="subMode === 'list'" class="carousel-wrapper">
                <button class="carousel-arrow left" @click="prevItem">❮</button>
                <div class="carousel-track-container">
                    <div class="carousel-track" :style="trackStyle">
                        <div 
                            v-for="(horse, index) in currentList" 
                            :key="index"
                            class="showroom-card-carousel"
                            :class="{ 'active': index === focusedIndex }"
                            @click="selectHorseByIndex(index)"
                        >
                            <div class="card-corner-tl">
                               <span class="horse-level" v-if="horse.xp">Lv.{{ getBondingLevel(horse.xp) }}</span>
                            </div>
                            <div class="card-corner-tr">
                               <img v-if="horse.selected == 1" src="@/assets/img/star-icon.png" class="star-icon" />
                            </div>
                            <div class="card-center-icon">
                               <img src="@/assets/img/head-horse-icon.png" class="white-icon-medium" />
                            </div>
                            <div class="card-body">
                               <h3 class="horse-name-show">{{ getHorseName(horse) }}</h3>
                               <p class="horse-breed-show">{{ horse.breed || horse.model }}</p>
                            </div>
                            <div class="card-footer" v-if="horse.dead == 1 || horse.writhe == 1">
                               <span v-if="horse.dead == 1" class="mini-badge dead">DEAD</span>
                               <span v-if="horse.writhe == 1" class="mini-badge injured">HURT</span>
                            </div>
                            <div class="selection-border" v-if="index === focusedIndex"></div>
                        </div>
                    </div>
                </div>
                <button class="carousel-arrow right" @click="nextItem">❯</button>
                <div class="key-hint">
                     <span>[◀ ▶] เลื่อน</span> • <span>[ENTER] จัดการม้า</span>
                </div>
            </div>

            <div v-else-if="subMode === 'actions' && selectedHorse" class="manage-action-view">
                <div class="selected-horse-header">
                    <h1>{{ getHorseName(selectedHorse) }}</h1>
                    <div class="sub-info">
                        <span>{{ selectedHorse.breed || selectedHorse.model }}</span> • 
                        <span>{{ selectedHorse.gender || 'Stallion' }}</span> • 
                        <span v-if="selectedHorse.xp">Bonding Lv.{{ getBondingLevel(selectedHorse.xp) }}</span>
                    </div>
                </div>

                <div class="manage-stats-wrapper">
                    <HorseStats :stats="selectedHorse.stats || {}" />
                </div>
                <div class="manage-info-right">
                    <HorseStorage :limit="selectedHorse.invLimit || 0" @open-cargo="openHorseCargo" />
                </div>

                <div class="bottom-showroom-list action-menu-list">
                    <div class="showroom-card" @click="performAction('call')" :class="{ disabled: selectedHorse.dead == 1 }">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/whistle-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">เรียกม้า</h3></div>
                    </div>
                    <div class="showroom-card" @click="performAction('return')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/return-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">ส่งม้ากลับคอก</h3></div>
                    </div>
                    <div class="showroom-card" @click="performAction('decorate')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/equipment-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">ซื้ออุปกรณ์ตกแต่ง</h3></div>
                    </div>
                    <div class="showroom-card" @click="performAction('heal')" :class="{ disabled: !(selectedHorse.dead == 1 || selectedHorse.writhe == 1) }">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/revive-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">รักษาม้า</h3><p class="horse-breed-show" v-if="reviveCost > 0">${{ reviveCost }}</p><p class="horse-breed-show" v-else>Free</p></div>
                    </div>
                    <div class="showroom-card" @click="performAction('setMain')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/star-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">ตั้งเป็นม้าตัวหลัก</h3></div>
                    </div>
                    <div class="showroom-card" @click="manageEquipment">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/equipment-manage-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">อุปกรณ์ตกแต่ง</h3></div>
                    </div>
                    <div class="showroom-card danger-card" @click="performAction('release')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/release-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show text-danger">ปล่อยม้า</h3></div>
                    </div>
                </div>
            </div>
            
            <div v-else-if="(subMode === 'equipment_cat' || subMode === 'decorate_cat') && selectedHorse" class="manage-action-view">
                 <div class="selected-horse-header">
                    <h1>{{ subMode === 'equipment_cat' ? 'จัดการอุปกรณ์' : 'ซื้ออุปกรณ์ตกแต่ง' }}</h1>
                    <div class="sub-info">เลือกหมวดหมู่</div>
                </div>
                
                <div class="carousel-wrapper" style="bottom: 120px;">
                    <button class="carousel-arrow left" @click="prevItem">❮</button>
                    <div class="carousel-track-container">
                        <div class="carousel-track" :style="trackStyle">
                            <div 
                                v-for="(category, index) in activeCarouselList" 
                                :key="index" 
                                class="showroom-card-carousel"
                                :class="{ 'active': index === focusedIndex }"
                                @click="selectItem(index)"
                            >
                                <div class="card-center-icon">
                                    <img src="@/assets/img/icon-manage/equipment-icon.png" class="white-icon-medium" />
                                </div>
                                <div class="card-body">
                                   <h3 class="horse-name-show">{{ formatCategoryName(category) }}</h3>
                                   <p class="horse-breed-show">
                                       {{ subMode === 'equipment_cat' ? getOwnedCountInCategory(category) : (compData[category] ? Object.keys(compData[category]).length : 0) }} Items
                                   </p>
                                </div>
                                <div class="selection-border" v-if="index === focusedIndex"></div>
                            </div>
                        </div>
                    </div>
                    <button class="carousel-arrow right" @click="nextItem">❯</button>
                    <div class="key-hint"><span>[ENTER] เลือกหมวดหมู่</span></div>
                </div>
            </div>

            <div v-else-if="(subMode === 'equipment_item' || subMode === 'decorate_item') && selectedHorse" class="manage-action-view">
                 <div class="selected-horse-header">
                     <h1>{{ formatCategoryName(selectedDecorCategory) }}</h1>
                     <div class="sub-info">รายการที่ {{ focusedIndex + 1 }} / {{ activeCarouselList.length }}</div>
                 </div>

                 <div class="carousel-wrapper" style="bottom: 120px;">
                    <button class="carousel-arrow left" @click="prevItem">❮</button>
                    <div class="carousel-track-container">
                        <div class="carousel-track" :style="trackStyle">
                            <div 
                                v-for="(item, index) in activeCarouselList" 
                                :key="index"
                                class="showroom-card-carousel"
                                :class="{ 'active': index === focusedIndex }"
                                @click="selectItem(index)"
                            >
                                <div class="card-corner-tr" v-if="isEquipped(item.hash)">
                                   <span class="mini-badge equipped">ON</span>
                                </div>
                                <div class="card-center-icon">
                                    <img src="@/assets/img/icon-manage/equipment-manage-icon.png" class="white-icon-medium" />
                                </div>
                                <div class="card-body">
                                    <h3 class="horse-name-show">{{ item.label || 'Item ' + (index+1) }}</h3>
                                    <p class="horse-breed-show" v-if="subMode === 'decorate_item'">
                                        <span v-if="getItemPrice(item) > 0">${{ getItemPrice(item) }}</span>
                                        <span v-if="getItemPrice(item) > 0 && item.goldPrice > 0"> | </span>
                                        <span v-if="item.goldPrice > 0" style="color: gold;">{{ item.goldPrice }} Gold</span>
                                        <span v-if="!getItemPrice(item) && !item.goldPrice">Free</span>
                                    </p>
                                </div>
                                <div class="selection-border" v-if="index === focusedIndex"></div>
                            </div>
                        </div>
                    </div>
                    <button class="carousel-arrow right" @click="nextItem">❯</button>
                </div>

                <div class="shop-controls-center">
                    <div v-if="subMode === 'equipment_item' && currentFocusedItem" class="buy-actions-row">
                        <button v-if="isEquipped(currentFocusedItem.hash)" class="action-btn btn-danger" @click="toggleEquip(currentFocusedItem.hash, false)">
                            ถอดอุปกรณ์ (UNEQUIP)
                        </button>
                        <button v-else class="action-btn btn-white" @click="toggleEquip(currentFocusedItem.hash, true)">
                            สวมใส่ (EQUIP)
                        </button>
                    </div>

                    <div v-if="subMode === 'decorate_item' && currentFocusedItem" class="buy-actions-row">
                        
                        <button v-if="getItemPrice(currentFocusedItem) > 0" 
                                class="action-btn btn-white" 
                                style="display: flex; align-items: center; justify-content: center; gap: 5px;"
                                @click="buyDecoration('cash')">
                            <span style="font-weight: 700; font-size: 16px;">$</span> 
                            {{ getItemPrice(currentFocusedItem) }}
                        </button>

                        <button v-if="currentFocusedItem.goldPrice > 0" 
                                class="action-btn btn-gold" 
                                style="display: flex; align-items: center; justify-content: center; gap: 5px;"
                                @click="buyDecoration('gold')">
                            <img src="@/assets/img/gold.png" style="width: 20px; height: 20px;" /> 
                            {{ currentFocusedItem.goldPrice }} Gold
                        </button>

                        <button v-if="getItemPrice(currentFocusedItem) == 0 && (!currentFocusedItem.goldPrice || currentFocusedItem.goldPrice == 0)"
                                class="action-btn btn-white" 
                                @click="buyDecoration('cash')">
                            สวมใส่ (ฟรี)
                        </button>

                    </div>
                </div>
            </div>

        </template>
      </template>


      <ShopView v-if="currentTab === 'shop'" @close-menu="closeMenu" />

      <button class="close-btn" @click="closeMenu">✕</button>
    </div>

    <ConfirmationModal :visible="showModal" title="ยืนยันการปล่อยม้า" @close="showModal = false">
      <p style="text-align: center; color: #fff;">คุณแน่ใจหรือไม่ว่าต้องการปล่อยม้าตัวนี้? <br> คุณจะไม่ได้รับเงินคืน</p>
      <div class="divider-menu-top" style="margin-top: 1rem; width: 100%; height: 1px; background: rgba(255,255,255,0.2);"></div>
      <div class="action-bar" style="flex-direction: row; gap: 10px; margin-top: 20px;">
        <button @click="confirmRelease" class="action-btn btn-danger">ยืนยัน</button>
        <button @click="showModal = false" class="action-btn btn-white">ยกเลิก</button>
      </div>
    </ConfirmationModal>

  </div>
</template>

<script>
import { mapState, mapGetters } from 'vuex';
import api from '@/api';
import HorseStats from '@/components/HorseStats.vue'; 
import HorseStorage from '@/components/HorseStorage.vue';
import ConfirmationModal from '@/components/ConfirmationModal.vue'; 
import ShopView from '@/components/ShopView.vue'; 

export default {
  name: "StableDashboard",
  components: { HorseStats, HorseStorage, ConfirmationModal, ShopView }, 
  data() {
      return {
          viewMode: 'home',
          subMode: 'list',
          reviveCost: 20,
          selectedDecorCategory: null,
          currentDecorIndex: 0,
          scrollOffsetCat: 0,
          showModal: false,
          hoveredHorse: null,
          focusedIndex: 0
      }
  },
  computed: {
    ...mapState(['location', 'currentTab', 'selectedHorse', 'compData']),
    ...mapGetters(['currentList']),
    
    activeCarouselList() {
        if (this.subMode === 'list') return this.currentList;
        if (this.subMode === 'equipment_cat') return this.ownedCategories;
        if (this.subMode === 'decorate_cat') return this.decorCategoryList;
        if (this.subMode === 'equipment_item' || this.subMode === 'decorate_item') {
            return this.currentCategoryItems;
        }
        return [];
    },

    currentFocusedItem() {
        if (!this.activeCarouselList || this.activeCarouselList.length === 0) return null;
        return this.activeCarouselList[this.focusedIndex];
    },

    trackStyle() {
        const cardWidth = 220; 
        const centerOffset = 100; 
        const shiftAmount = (this.focusedIndex * cardWidth) + centerOffset;
        return { transform: `translateX(-${shiftAmount}px)` };
    },

    decorCategoryList() { if (!this.compData) return []; return Object.keys(this.compData).sort(); },
    ownedItemsList() {
        if (!this.selectedHorse) return [];
        let owned = [];
        try {
            if (this.selectedHorse.owned_components && this.selectedHorse.owned_components !== '[]') {
                const parsedOwned = JSON.parse(this.selectedHorse.owned_components);
                owned = [...parsedOwned];
            }
            if (this.selectedHorse.components && this.selectedHorse.components !== '[]') {
                const equipped = JSON.parse(this.selectedHorse.components);
                owned = [...owned, ...equipped];
            }
            owned = [...new Set(owned)];
        } catch (e) { console.log("Error parsing components"); }
        return owned.map(Number);
    },
    hasAnyOwnedItems() { return this.ownedItemsList.length > 0; },
    ownedCategories() {
        if (!this.compData) return [];
        return this.decorCategoryList.filter(cat => this.getOwnedCountInCategory(cat) > 0);
    },
    currentCategoryItems() {
        if (!this.selectedDecorCategory || !this.compData) return [];
        let items = this.compData[this.selectedDecorCategory];
        if (typeof items === 'object' && !Array.isArray(items)) items = Object.values(items);
        if (this.subMode === 'equipment_item') {
            const owned = this.ownedItemsList;
            return items.filter(item => owned.includes(Number(item.hash)));
        }
        return items; 
    },
    currentDecorItem() { return this.currentCategoryItems[this.currentDecorIndex] || {}; }
  },
  
  mounted() { 
      window.addEventListener('keydown', this.handleKeydown); 
      if(this.currentList.length > 0) this.onHorseHover(this.currentList[0]);
  },
  beforeUnmount() { window.removeEventListener('keydown', this.handleKeydown); },

  watch: {
      selectedHorse(newVal) {
          if (this.currentTab === 'owned' && newVal) {
              this.previewMyHorse(newVal);
          }
      },
      subMode(newVal) {
          this.focusedIndex = 0;
          if (newVal === 'list' && this.currentList.length > 0) {
              this.onHorseHover(this.currentList[0]);
          }
      },
      focusedIndex() {
          if (this.subMode === 'decorate_item') this.previewDecoration();
      }
  },
  methods: {
    handleKeydown(e) {
        const carouselModes = ['list', 'equipment_cat', 'decorate_cat', 'equipment_item', 'decorate_item'];
        if (this.currentTab === 'owned' && carouselModes.includes(this.subMode)) {
            if (e.key === 'ArrowLeft') this.prevItem();
            else if (e.key === 'ArrowRight') this.nextItem();
            else if (e.key === 'Enter') this.selectItem(this.focusedIndex);
        }
    },

    prevItem() {
        if (this.focusedIndex > 0) {
            this.focusedIndex--;
            this.onListScroll();
        }
    },
    nextItem() {
        if (this.focusedIndex < this.activeCarouselList.length - 1) {
            this.focusedIndex++;
            this.onListScroll();
        }
    },
    onListScroll() {
        if (this.subMode === 'list') {
            this.onHorseHover(this.currentList[this.focusedIndex]);
        }
    },
    
    selectItem(index) {
        this.focusedIndex = index;
        const item = this.activeCarouselList[index];
        if (!item) return;

        if (this.subMode === 'list') {
            this.selectHorse(item);
        } else if (this.subMode === 'equipment_cat') {
            this.openEquipmentItems(item);
        } else if (this.subMode === 'decorate_cat') {
            this.openDecorateItems(item);
        }
    },

    selectHorseByIndex(index) {
        this.focusedIndex = index;
        this.selectItem(index);
    },

    openDecorateCategories() {
        api.post("selectHorse", { horseId: this.selectedHorse.id });
        this.subMode = 'decorate_cat'; 
    },
    manageEquipment() {
        api.post("selectHorse", { horseId: this.selectedHorse.id });
        this.subMode = 'equipment_cat'; 
    },
    openDecorateItems(category) {
        this.selectedDecorCategory = category; 
        this.subMode = 'decorate_item'; 
    },
    openEquipmentItems(category) {
        this.selectedDecorCategory = category; 
        this.subMode = 'equipment_item';
    },
    
    getItemPrice(item) { return item.cashPrice || item.price || item.cash || 0; },
    goToShop() { this.$store.dispatch('selectTab', 'shop'); },
    onHorseHover(horse) {
        this.hoveredHorse = horse;
        if (this.currentTab === 'owned') { this.previewMyHorse(horse); } 
    },
    enterMode(mode) { 
        this.$store.dispatch('selectTab', mode); 
        this.viewMode = 'content'; 
        this.subMode = 'list'; 
        this.hoveredHorse = null; 
        this.$store.dispatch('selectHorse', null);
        this.focusedIndex = 0; 
        setTimeout(() => {
            if(this.currentTab === 'owned' && this.currentList.length > 0) {
                this.onHorseHover(this.currentList[0]);
            }
        }, 100);
    },
    getBackLabel() {
        if (['decorate_item', 'equipment_item'].includes(this.subMode)) return 'CATEGORIES';
        if (['decorate_cat', 'equipment_cat'].includes(this.subMode)) return 'ACTIONS';
        if (this.subMode === 'actions') return 'HORSE LIST';
        return 'HOME';
    },
    handleBack() {
        if (this.currentTab === 'owned') {
            if (this.subMode === 'decorate_item') { this.subMode = 'decorate_cat'; return; }
            if (this.subMode === 'equipment_item') { this.subMode = 'equipment_cat'; return; }
            if (this.subMode === 'decorate_cat' || this.subMode === 'equipment_cat') {
                this.subMode = 'actions'; 
                this.previewMyHorse(this.selectedHorse); 
                return;
            }
            if (this.subMode === 'actions') {
                this.subMode = 'list';
                this.$store.dispatch('selectHorse', null);
                setTimeout(() => {
                    if(this.currentList[this.focusedIndex]) this.onHorseHover(this.currentList[this.focusedIndex]);
                }, 100);
                return;
            }
        }
        this.goHome();
    },
    
    previewDecoration() {
        const item = this.currentFocusedItem;
        if (item && item.hash) { 
            const price = this.getItemPrice(item);
            api.post(this.selectedDecorCategory, { hash: item.hash, price: price, id: 0 }); 
        }
    },
    
    // [แก้ไข] ฟังก์ชันซื้อ (ส่งค่าตัวเลขที่ถูกต้อง)
    buyDecoration(currency) {
        const item = this.currentFocusedItem;
        if (!item || !item.hash) return;
        
        let cashCost = 0;
        let goldCost = 0;
        let currencyType = 0;

        if (currency === 'gold') {
            goldCost = parseInt(item.goldPrice) || 0;
            currencyType = 1;
        } else {
            cashCost = parseInt(this.getItemPrice(item)) || 0;
            currencyType = 0;
        }
        
        // ส่งคำสั่ง CloseStable เพียงครั้งเดียวเพื่อตัดเงินและบันทึก
        // ตัดบรรทัด horseAction: saveOwned ออกแล้ว
        api.post("CloseStable", { 
            MenuAction: "save", 
            cashPrice: cashCost, 
            goldPrice: goldCost, 
            currencyType: currencyType 
        });
        
        setTimeout(() => this.closeMenu(), 500);
    },

    toggleEquip(hash, equip) {
        if (equip) {
            api.post("horseAction", { action: 'equipOwned', horseId: this.selectedHorse.id, componentHash: hash });
        } else {
            api.post("horseAction", { action: 'unequipOne', horseId: this.selectedHorse.id, componentHash: hash });
        }
        setTimeout(() => this.closeMenu(), 300);
    },

    goHome() {
      this.viewMode = 'home';
      this.$store.dispatch('selectHorse', null);
      api.post("loadHorse", { horseModel: 'CLEAR' });
    },
    openHorseCargo() {
        if (!this.selectedHorse || !this.selectedHorse.id) return;
        api.post("OpenHorseCargo", { horseId: this.selectedHorse.id });
        this.closeMenu(); 
    },
    selectHorse(horse) {
      this.$store.dispatch('selectHorse', horse);
      if (this.currentTab === 'owned') { this.subMode = 'actions'; }
    },
    getHorseName(horse) { return horse.name || horse.breed || "Unknown Horse"; },
    getBondingLevel(xp) { if (xp >= 2400) return 4; if (xp >= 1700) return 3; if (xp >= 900) return 2; return 1; },
    closeMenu() {
      api.post("CloseStable", { MenuAction: "Close" });
      this.$store.dispatch('closeDashboard');
      setTimeout(() => { this.viewMode = 'home'; this.subMode = 'list'; }, 500);
    },
    previewMyHorse(horse) { api.post("loadMyHorse", { HorseModel: horse.model, HorseComp: horse.components, HorseId: horse.id, HorseGender: horse.gender }); },
    getOwnedCountInCategory(category) {
        const items = this.compData[category];
        if (!items) return 0;
        const list = Array.isArray(items) ? items : Object.values(items);
        const owned = this.ownedItemsList;
        return list.filter(item => owned.includes(Number(item.hash))).length;
    },
    isEquipped(hash) {
        try {
            const equipped = JSON.parse(this.selectedHorse.components || '[]');
            return equipped.includes(Number(hash));
        } catch(e) { return false; }
    },
    formatCategoryName(name) { return name ? name.replace(/([A-Z])/g, ' $1').trim() : ''; },
    performAction(action) {
        if (!this.selectedHorse) return;
        if (action === 'release') { this.showModal = true; return; }
        if (action === 'decorate') { this.openDecorateCategories(); return; }
        api.post("horseAction", { action: action, horseId: this.selectedHorse.id, horseModel: this.selectedHorse.model });
        if (['call', 'return'].includes(action)) this.closeMenu();
        if (['heal', 'setMain'].includes(action)) setTimeout(() => this.closeMenu(), 300);
    },
    confirmRelease() {
        api.post("horseAction", { action: 'release', horseId: this.selectedHorse.id, horseModel: this.selectedHorse.model });
        this.showModal = false;
        this.closeMenu();
    }
  }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Pridi:wght@300;400;500;600;700&display=swap');
* { font-family: 'Pridi', serif !important; }
.dashboard-container { display: flex; width: 100vw; height: 100vh; position: relative; color: #f0f0f0; }

/* ============ Carousel Styles ============ */
.carousel-wrapper {
    position: absolute; bottom: 40px; left: 0; width: 100%;
    display: flex; flex-direction: column; align-items: center;
    z-index: 10;
}

.carousel-track-container {
    width: 100%; height: 220px;
    overflow: hidden; 
    position: relative;
    mask-image: linear-gradient(to right, transparent 0%, black 20%, black 80%, transparent 100%);
    -webkit-mask-image: linear-gradient(to right, transparent 0%, black 20%, black 80%, transparent 100%);
}

.carousel-track {
    display: flex; gap: 20px;
    position: absolute; left: 50%; top: 50%;
    transform-origin: 0 0; margin-top: -80px; /* half of 160px height */
    transition: transform 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.showroom-card-carousel {
    width: 200px; height: 160px;
    background: rgba(20, 20, 20, 0.8);
    border: 1px solid rgba(255,255,255,0.1); border-radius: 8px;
    display: flex; flex-direction: column; justify-content: center; align-items: center;
    gap: 10px; cursor: pointer; flex-shrink: 0; position: relative;
    transition: all 0.3s ease; opacity: 0.5; transform: scale(0.9);
}

.showroom-card-carousel.active {
    opacity: 1; transform: scale(1.1);
    background: rgba(40, 40, 40, 0.95);
    border-color: #d4af37;
    box-shadow: 0 10px 30px rgba(0,0,0,0.5); z-index: 2;
}

.selection-border {
    position: absolute; top: -2px; left: -2px; right: -2px; bottom: -2px;
    border: 2px solid #d4af37; border-radius: 10px;
    box-shadow: 0 0 15px rgba(212, 175, 55, 0.5); pointer-events: none;
}

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

/* Styles เดิม */
.btn-danger { background: #c0392b; color: #fff; box-shadow: none !important; }
.btn-danger:hover { background: #e74c3c; box-shadow: none !important; }
.btn-gold { background: #DAA520; color: #000; box-shadow: none !important; }
.btn-gold:hover { background: #FFD700 !important; box-shadow: 0 0 15px rgba(255,215,0,0.4) !important; transform: translateY(-1px); }

.empty-notif { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; color: #888; }
.empty-notif h2 { color: #fff; font-size: 24px; margin-bottom: 10px; }
.shop-controls-center { position: absolute; bottom: 50px; left: 50%; transform: translateX(-50%); display: flex; flex-direction: column; align-items: center; gap: 20px; width: 100%; z-index: 20; }
.buy-actions-row { display: flex; gap: 15px; justify-content: center; }
.buy-btn-small { margin-top: 15px; padding: 10px 40px; background: #fff; color: #000; border: none; font-weight: bold; cursor: pointer; text-transform: uppercase; border-radius: 30px; font-size: 13px; letter-spacing: 1px; transition: 0.2s; box-shadow: none !important; }
.buy-btn-small:hover { background: #d4af37; color: #fff; transform: translateY(-2px); box-shadow: none !important; }
.empty-state-view { position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; background: rgba(0,0,0,0.6); z-index: 5; }
.empty-content { text-align: center; }
.white-icon-large { width: 120px; height: 120px; object-fit: contain; filter: brightness(0) invert(1); opacity: 0.5; margin-bottom: 20px; }
.empty-content h2 { margin: 0; font-size: 36px; font-weight: 600; color: #fff; letter-spacing: 2px; }
.empty-content p { font-size: 16px; color: #888; margin-top: 10px; font-weight: 300; }
.floating-back-btn { position: absolute; top: 40px; left: 40px; background: rgba(0,0,0,0.5); border: 1px solid rgba(255,255,255,0.2); color: #fff; padding: 10px 20px; border-radius: 30px; font-family: inherit; font-weight: 500; cursor: pointer; display: flex; align-items: center; gap: 5px; z-index: 100; transition: 0.3s; }
.floating-back-btn:hover { background: #fff; color: #000; border-color: #fff; }
.close-btn { position: absolute; top: 30px; right: 30px; background: transparent; border: none; color: #666; font-size: 20px; cursor: pointer; transition: 0.3s; z-index: 100; }
.close-btn:hover { color: #fff; transform: rotate(90deg); }
.bottom-showroom-list { position: absolute; bottom: 40px; left: 50%; transform: translateX(-50%); width: 90%; height: 200px; display: flex; justify-content: center; align-items: center; gap: 20px; overflow-x: auto; padding-top: 25px; padding-bottom: 10px; z-index: 10; }
.action-menu-list { bottom: 120px; }
.bottom-showroom-list::-webkit-scrollbar { height: 6px; }
.bottom-showroom-list::-webkit-scrollbar-track { background: rgba(0,0,0,0.3); border-radius: 3px; }
.bottom-showroom-list::-webkit-scrollbar-thumb { background: #444; border-radius: 3px; }
.showroom-card { min-width: 145px; height: 145px; background: rgba(22, 22, 22, 0.9); border: 1px solid rgba(255,255,255,0.1); border-radius: 6px; display: flex; flex-direction: column; padding: 15px; cursor: pointer; position: relative; transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1); justify-content: center; align-items: center; gap: 15px; }
.showroom-card:hover { transform: translateY(-10px); background: rgba(35, 35, 35, 0.95); border-color: rgba(255,255,255,0.3); }
.showroom-card.selected { border-color: #fff; background: rgba(50, 50, 50, 0.95); box-shadow: 0 0 15px rgba(255,255,255,0.1); transform: translateY(-10px); }
.card-corner-tl { position: absolute; top: 8px; left: 8px; z-index: 2; }
.card-corner-tr { position: absolute; top: 8px; right: 8px; z-index: 2; }
.horse-level { font-size: 10px; color: #aaa; background: rgba(0,0,0,0.5); padding: 1px 4px; border-radius: 3px; font-weight: 500; }
.star-icon { width: 18px; height: 18px; object-fit: contain; filter: brightness(0) invert(1); opacity: 0.9; }
.card-center-icon { margin: 0; margin-top: -10px; }
.white-icon-medium { width: 50px; height: 50px; object-fit: contain; filter: brightness(0) invert(1); opacity: 0.9; }
.card-body { text-align: center; display: flex; flex-direction: column; align-items: center; justify-content: center; width: 100%; }
.horse-name-show { font-size: 14px; font-weight: 600; color: #fff; margin: 0 auto; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 125px; }
.horse-breed-show { font-size: 10px; color: #888; margin: 2px 0 0 0; }
.card-footer { position: absolute; bottom: 8px; left: 0; width: 100%; display: flex; justify-content: center; gap: 4px; margin-top: 0; }
.mini-badge { font-size: 8px; padding: 2px 5px; border-radius: 2px; font-weight: 700; }
.mini-badge.dead { background: #c0392b; color: #fff; } 
.mini-badge.injured { background: #e67e22; color: #fff; } 
.showroom-card.disabled { opacity: 0.4; pointer-events: none; filter: grayscale(1); }
.showroom-card.danger-card:hover { border-color: #c0392b; background: rgba(192, 57, 43, 0.2); }
.text-danger { color: #e74c3c; }
.manage-action-view { position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: flex; flex-direction: column; justify-content: flex-end; align-items: center; padding-bottom: 50px; background: linear-gradient(to top, rgba(0,0,0,0.8), transparent 50%); z-index: 5; }
.selected-horse-header { position: absolute; top: 5%; left: 0; width: 100%; text-align: center; text-shadow: 0 2px 10px rgba(0,0,0,0.8); pointer-events: none; z-index: 20; }
.selected-horse-header h1 { font-size: 48px; margin: 0; font-weight: 600; color: #fff; letter-spacing: 2px; }
.selected-horse-header .sub-info { font-size: 16px; color: #ccc; margin-top: 5px; font-weight: 300; }
.home-menu { width: 100%; height: 100%; display: flex; flex-direction: column; justify-content: center; align-items: center; background: rgba(0,0,0,0.6); }
.showroom-header { text-align: center; margin-bottom: 60px; }
.showroom-header h1 { font-size: 56px; margin: 0; font-weight: 600; text-transform: uppercase; letter-spacing: 4px; color: #fff; }
.showroom-header p { font-size: 16px; color: #888; margin-top: 5px; font-weight: 300; }
.menu-grid { display: flex; gap: 40px; }
.menu-card { width: 320px; height: 280px; background: rgba(22, 22, 22, 0.95); border: 1px solid rgba(255,255,255,0.08); border-radius: 8px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1); position: relative; }
.menu-card:hover { transform: translateY(-8px); border-color: rgba(255,255,255,0.25); box-shadow: 0 15px 40px rgba(0,0,0,0.5); }
.card-content { text-align: center; padding: 20px; }
.big-icon { margin-bottom: 20px; }
.menu-card h2 { margin: 0; font-size: 22px; font-weight: 500; text-transform: uppercase; letter-spacing: 1px; color: #e0e0e0; transition: color 0.3s; }
.menu-card p { font-size: 13px; color: #666; margin-top: 8px; font-weight: 300; transition: color 0.3s; }
.menu-card:hover h2 { color: #fff; }
.menu-card:hover p { color: #aaa; }
.close-btn-home { margin-top: 60px; padding: 10px 40px; background: transparent; border: 1px solid rgba(255,255,255,0.15); color: #888; font-family: inherit; font-size: 13px; letter-spacing: 2px; border-radius: 30px; cursor: pointer; transition: all 0.3s; }
.close-btn-home:hover { border-color: #fff; color: #fff; letter-spacing: 3px; }
.white-icon { width: 90px; height: 90px; object-fit: contain; filter: brightness(0) invert(1); opacity: 0.8; transition: all 0.4s ease; }
.menu-card:hover .white-icon { opacity: 1; transform: scale(1.08); filter: brightness(0) invert(1) drop-shadow(0 0 8px rgba(255,255,255,0.3)); }
.white-icon-small { width: 20px; height: 20px; object-fit: contain; filter: brightness(0) invert(1); opacity: 0.8; }
.details-header h1 { margin: 0; font-size: 32px; font-weight: 600; letter-spacing: 1px; }
.sub-info { color: #666; font-size: 14px; margin-bottom: 25px; margin-top: 5px; }
.action-bar { display: flex; flex-direction: column; gap: 10px; margin-top: 10px; }
.form-group { display: flex; flex-direction: column; gap: 6px; margin-bottom: 12px; }
.form-group label { font-size: 11px; color: #666; text-transform: uppercase; letter-spacing: 0.5px; }
.custom-input { width: 100%; padding: 12px; background: rgba(255,255,255,0.05); color: #fff; border: 1px solid #333; border-radius: 4px; font-family: inherit; font-size: 14px; box-sizing: border-box; transition: border 0.2s; }
.custom-input:focus { border-color: #666; outline: none; }
.action-btn { width: 100%; padding: 14px; border: none; border-radius: 4px; font-family: inherit; font-weight: 600; cursor: pointer; text-transform: uppercase; font-size: 13px; letter-spacing: 1px; transition: all 0.3s ease; }
.action-btn:disabled { opacity: 0.3; cursor: not-allowed; }
.btn-white { background: #e0e0e0; color: #000; }
.btn-white:hover { background: #fff; box-shadow: 0 0 15px rgba(255,255,255,0.3); transform: translateY(-1px); }
.btn-outline { background: transparent; border: 1px solid rgba(255,255,255,0.2); color: #ccc; }
.btn-outline:hover { border-color: #fff; color: #fff; letter-spacing: 2px; }
.btn-ghost { background: transparent; border: 1px solid rgba(255,255,255,0.05); color: #666; }
.btn-ghost:hover { border-color: rgba(255,255,255,0.2); color: #aaa; }
.btn-text { background: transparent; color: #444; font-size: 11px; margin-top: 5px; }
.btn-text:hover { color: #888; }
.manage-stats-wrapper {
  position: absolute; top: 40%; left: 80px;         
  transform: translateY(-50%); width: 320px; z-index: 20;
}
.manage-info-right {
  position: absolute; top: 40%; right: 80px;   
  transform: translateY(-50%); width: 320px; z-index: 20;
}
.status-badge { padding: 5px 15px; border-radius: 4px; font-size: 12px; font-weight: bold; letter-spacing: 1px; margin-bottom: 10px; }
.status-badge.equipped { background: rgba(46, 204, 113, 0.2); color: #2ecc71; border: 1px solid #2ecc71; }
.status-badge.stored { background: rgba(255, 255, 255, 0.1); color: #aaa; border: 1px solid #666; }
</style>