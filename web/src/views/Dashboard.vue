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
      
      <button class="floating-back-btn" @click="handleBack">
        <i class="fas fa-chevron-left"></i> {{ getBackLabel() }}
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
            <div v-if="subMode === 'list'" class="bottom-showroom-list">
              <div 
                v-for="(horse, index) in currentList" 
                :key="index"
                class="showroom-card"
                @click="selectHorse(horse)"
                @mouseenter="onHorseHover(horse)"
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
                    <HorseStorage 
                    :limit="selectedHorse.invLimit || 0" 
                    @open-cargo="openHorseCargo"
                    />
                </div>

                <div class="bottom-showroom-list action-menu-list">
                    <div class="showroom-card" @click="performAction('call')" :class="{ disabled: selectedHorse.dead == 1 }">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/whistle-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">เรียกม้า</h3><p class="horse-breed-show">ผิวปากเรียกม้าคู่ใจ</p></div>
                    </div>
                    <div class="showroom-card" @click="performAction('return')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/return-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">ส่งม้ากลับคอก</h3><p class="horse-breed-show">พาคู่หูกลับคอก</p></div>
                    </div>
                    <div class="showroom-card" @click="performAction('decorate')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/equipment-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">ซื้ออุปกรณ์ตกแต่ง</h3><p class="horse-breed-show">เลือกซื้ออุปกรณ์และตกแต่งม้าคู่ใจ</p></div>
                    </div>
                    <div class="showroom-card" @click="performAction('heal')" :class="{ disabled: !(selectedHorse.dead == 1 || selectedHorse.writhe == 1) }">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/revive-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">รักษาม้า</h3><p class="horse-breed-show" v-if="reviveCost > 0">${{ reviveCost }}</p><p class="horse-breed-show" v-else>Free</p></div>
                    </div>
                    <div class="showroom-card" @click="performAction('setMain')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/star-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">ตั้งเป็นม้าตัวหลัก</h3><p class="horse-breed-show">ตั้งม้าตัวนี้เป็นหัวใจของคอก</p></div>
                    </div>
                    <div class="showroom-card" @click="manageEquipment">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/equipment-manage-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show">อุปกรณ์ตกแต่ง</h3><p class="horse-breed-show">ดูแลและจัดอุปกรณ์ม้าคู่ใจ</p></div>
                    </div>
                    <div class="showroom-card danger-card" @click="performAction('release')">
                        <div class="card-center-icon"><img src="@/assets/img/icon-manage/release-icon.png" class="white-icon-medium" /></div>
                        <div class="card-body"><h3 class="horse-name-show text-danger">ปล่อยม้า</h3><p class="horse-breed-show">ปล่อยคู่หูของคุณไปตามทาง</p></div>
                    </div>
                </div>
            </div>

            <div v-else-if="subMode === 'equipment_cat' && selectedHorse" class="manage-action-view">
                <div class="selected-horse-header">
                    <h1>จัดการอุปกรณ์ตกแต่งม้า</h1>
                    <div class="sub-info">เลือกประเภทเพื่อดูสิ่งของที่เป็นของคุณ</div>
                </div>
                
                <div v-if="!hasAnyOwnedItems" class="empty-notif">
                    <h2>ยังไม่มีอุปกรณ์</h2>
                    <p>ไปที่เมนู "ซื้ออุปกรณ์ตกแต่ง" เลือกซื้อของให้ม้าก่อน</p>
                </div>

                <div v-else class="carousel-container-wide">
                    <button class="nav-arrow left" @click="scrollLeftCat">❮</button>

                    <div class="decor-grid-6">
                        <div 
                            v-for="(category, index) in visibleOwnedCats" 
                            :key="index" 
                            class="showroom-card"
                            @click="openEquipmentItems(category)"
                        >
                            <div class="card-center-icon">
                                <img src="@/assets/img/icon-manage/equipment-icon.png" class="white-icon-medium" />
                            </div>
                            <div class="card-body">
                               <h3 class="horse-name-show">{{ formatCategoryName(category) }}</h3>
                               <p class="horse-breed-show">{{ getOwnedCountInCategory(category) }} Items</p>
                            </div>
                        </div>
                    </div>

                    <button class="nav-arrow right" @click="scrollRightCat">❯</button>
                </div>
                
                <div style="position:absolute; bottom: 30px; color: #666; font-size: 12px;">
                    Use Arrow Keys ◀ ▶ to browse
                </div>
            </div>

            <div v-else-if="subMode === 'equipment_item' && selectedHorse" class="manage-action-view">
                <div class="selected-horse-header">
                    <h1>{{ formatCategoryName(selectedDecorCategory) }}</h1>
                    <div class="sub-info">Manage your owned items</div>
                </div>

                <div class="carousel-container">
                    <div class="decor-selector-center">
                        
                        <div class="status-badge" :class="isEquipped(currentDecorItem.hash) ? 'equipped' : 'stored'">
                            {{ isEquipped(currentDecorItem.hash) ? 'EQUIPPED' : 'IN INVENTORY' }}
                        </div>

                        <h2 class="decor-item-name">Item {{ currentDecorIndex + 1 }}</h2>
                        
                        <div class="decor-nav-row">
                            <button class="nav-arrow" @click="prevItem">❮</button>
                            <span class="decor-counter">{{ currentDecorIndex + 1 }} / {{ currentCategoryItems.length }}</span>
                            <button class="nav-arrow" @click="nextItem">❯</button>
                        </div>

                        <button v-if="isEquipped(currentDecorItem.hash)" class="buy-btn-small btn-danger" @click="toggleEquip(currentDecorItem.hash, false)">
                            UNEQUIP
                        </button>
                        <button v-else class="buy-btn-small" @click="toggleEquip(currentDecorItem.hash, true)">
                            EQUIP
                        </button>
                    </div>
                </div>
                
                <div style="position:absolute; bottom: 30px; color: #666; font-size: 12px;">
                    Use Arrow Keys ◀ ▶ to change items
                </div>
            </div>

            <div v-else-if="subMode === 'decorate_cat' && selectedHorse" class="manage-action-view">
                <div class="selected-horse-header">
                    <h1>อุปกรณ์ตกแต่งม้า</h1>
                    <div class="sub-info">เลือกหมวดหมู่ที่ต้องการ</div>
                </div>
                
                <div class="carousel-container-wide">
                    <button class="nav-arrow left" @click="scrollLeftCat">❮</button>

                    <div class="decor-grid-6">
                        <div 
                            v-for="(category, index) in visibleDecorCats" 
                            :key="index" 
                            class="showroom-card"
                            @click="openDecorateItems(category)"
                        >
                            <div class="card-center-icon">
                                <img src="@/assets/img/icon-manage/equipment-icon.png" class="white-icon-medium" />
                            </div>
                            <div class="card-body">
                               <h3 class="horse-name-show">{{ formatCategoryName(category) }}</h3>
                               <p class="horse-breed-show">{{ compData[category] ? Object.keys(compData[category]).length : 0 }} Items</p>
                            </div>
                        </div>
                    </div>

                    <button class="nav-arrow right" @click="scrollRightCat">❯</button>
                </div>
            </div>

            <div v-else-if="subMode === 'decorate_item' && selectedHorse" class="manage-action-view">
                <div class="selected-horse-header">
                    <h1>{{ formatCategoryName(selectedDecorCategory) }}</h1>
                </div>

                <div class="carousel-container">
                    <div class="decor-selector-center">
                        
                        <h2 class="decor-item-name" v-if="getItemPrice(currentDecorItem) > 0">${{ getItemPrice(currentDecorItem) }}</h2>
                        <h2 class="decor-item-name" v-else>ฟรี</h2>
                        
                        <div class="decor-nav-row">
                            <button class="nav-arrow" @click="prevItem">❮</button>
                            <span class="decor-counter">รายการที่ {{ currentDecorIndex + 1 }} จาก {{ currentCategoryItems.length }}</span>
                            <button class="nav-arrow" @click="nextItem">❯</button>
                        </div>

                        <button class="buy-btn-small" @click="buyDecoration">
                            ซื้อ / สวมใส่
                        </button>
                    </div>
                </div>
            </div>

        </template>
      </template>


      <template v-if="currentTab === 'shop'">
        <div class="sidebar flat-panel">
          <div class="sidebar-header">
            <h2 class="stable-title">MARKETPLACE</h2>
          </div>
          <div class="horse-list-wrapper custom-scroll">
            <div 
              v-for="(horse, index) in currentList" 
              :key="index"
              class="horse-card"
              :class="{ selected: isSelected(horse) }"
              @click="selectHorse(horse)"
              @mouseenter="onHorseHover(horse)"
            >
              <div class="card-icon">
                <img src="@/assets/img/buy-horse-icon.png" class="white-icon-small" />
              </div>
              <div class="card-info">
                <h3 class="horse-name">{{ getHorseName(horse) }}</h3>
                <p class="horse-breed">{{ horse.breed || horse.model }}</p>
                <div class="price-tag">
                  <span v-if="horse.colors && Object.values(horse.colors)[0].cashPrice > 0" class="price-text">
                    ${{ Object.values(horse.colors)[0].cashPrice }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="details-panel flat-panel" v-if="selectedHorse">
            <div class="details-header">
              <h1>{{ getHorseName(selectedHorse) }}</h1>
              <div class="sub-info">
                  <span>{{ selectedHorse.gender || 'Stallion' }}</span> • 
                  <span>{{ selectedHorse.breed || selectedHorse.model }}</span>
              </div>
            </div>
            <div class="stats-wrapper">
              <HorseStats :stats="selectedHorse.stats || {}" />
            </div>
            <div class="action-bar">
              <div class="shop-form">
                 <div class="form-group" v-if="selectedHorse.colors">
                     <label>Select Color</label>
                     <select v-model="selectedColorModel" class="custom-input">
                         <option v-for="(data, model) in selectedHorse.colors" :key="model" :value="model">
                             {{ data.color }} - ${{ data.cashPrice }}
                         </option>
                     </select>
                 </div>
                 <div class="form-group">
                     <label>Name your horse</label>
                     <input type="text" v-model="newHorseName" placeholder="Enter horse name..." class="custom-input" maxlength="20" />
                 </div>
                 <button class="action-btn btn-white" @click="buyHorse" :disabled="!newHorseName">PURCHASE (${{ getSelectedPrice() }})</button>
              </div>
            </div>
        </div>
      </template>

      <button class="close-btn" @click="closeMenu">✕</button>
    </div>

  </div>
</template>

<script>
import { mapState, mapGetters } from 'vuex';
import HorseStats from '@/components/HorseStats.vue'; 
import HorseStorage from '@/components/HorseStorage.vue'; // <-- เพิ่มบรรทัดนี้
import api from '@/api';

export default {
  name: "StableDashboard",
  components: { HorseStats, HorseStorage },
  data() {
      return {
          viewMode: 'home',
          subMode: 'list',
          selectedColorModel: null,
          newHorseName: "",
          reviveCost: 20,
          selectedDecorCategory: null,
          currentDecorIndex: 0,
          scrollOffsetCat: 0
      }
  },
  computed: {
    ...mapState(['location', 'currentTab', 'selectedHorse', 'compData']),
    ...mapGetters(['currentList']),
    
    decorCategoryList() {
        if (!this.compData) return [];
        return Object.keys(this.compData).sort();
    },
    
    // --- OWNED EQUIPMENT LOGIC (NEW) ---
    ownedItemsList() {
        if (!this.selectedHorse) return [];
        let owned = [];
        try {
            // 1. ของที่ซื้อเก็บไว้
            if (this.selectedHorse.owned_components && this.selectedHorse.owned_components !== '[]') {
                const parsedOwned = JSON.parse(this.selectedHorse.owned_components);
                owned = [...parsedOwned];
            }
            // 2. ของที่ใส่อยู่ (ต้องนับว่าเป็นของที่มีด้วย)
            if (this.selectedHorse.components && this.selectedHorse.components !== '[]') {
                const equipped = JSON.parse(this.selectedHorse.components);
                owned = [...owned, ...equipped];
            }
            // ลบตัวซ้ำ
            owned = [...new Set(owned)];
        } catch (e) { 
            console.log("Error parsing components"); 
        }
        return owned.map(Number);
    },
    hasAnyOwnedItems() {
        return this.ownedItemsList.length > 0;
    },
    ownedCategories() {
        // กรองหาหมวดที่มีของอย่างน้อย 1 ชิ้น
        if (!this.compData) return [];
        return this.decorCategoryList.filter(cat => this.getOwnedCountInCategory(cat) > 0);
    },
    visibleOwnedCats() {
        const list = this.ownedCategories;
        if (!list.length) return [];
        return list.slice(this.scrollOffsetCat, this.scrollOffsetCat + 6);
    },
    visibleDecorCats() {
        // สำหรับหน้า Shop (แสดงทุกหมวด)
        const list = this.decorCategoryList;
        return list.slice(this.scrollOffsetCat, this.scrollOffsetCat + 6);
    },
    
    currentCategoryItems() {
        if (!this.selectedDecorCategory || !this.compData) return [];
        let items = this.compData[this.selectedDecorCategory];
        if (typeof items === 'object' && !Array.isArray(items)) items = Object.values(items);
        
        // ถ้าอยู่ในโหมดจัดการอุปกรณ์ (Equipment) ให้กรองเอาเฉพาะของที่มี
        if (this.subMode === 'equipment_item') {
            const owned = this.ownedItemsList;
            return items.filter(item => owned.includes(Number(item.hash)));
        }
        // ถ้าอยู่หน้า Shop (Decorate) ให้แสดงทั้งหมด
        return items; 
    },
    currentDecorItem() {
        return this.currentCategoryItems[this.currentDecorIndex] || {};
    }
  },
  
  mounted() { window.addEventListener('keydown', this.handleKeydown); },
  beforeUnmount() { window.removeEventListener('keydown', this.handleKeydown); },

  watch: {
      selectedHorse(newVal) {
          if (this.currentTab === 'shop' && newVal && newVal.colors) {
              this.selectedColorModel = Object.keys(newVal.colors)[0];
              this.previewHorse(this.selectedColorModel); 
              this.newHorseName = ""; 
          } else if (this.currentTab === 'owned' && newVal) {
              this.previewMyHorse(newVal);
          }
      },
      selectedColorModel(newVal) { if (this.currentTab === 'shop' && newVal) this.previewHorse(newVal); },
      currentDecorIndex() { 
          // Preview เฉพาะตอนอยู่หน้า Shop
          if (this.subMode === 'decorate_item') this.previewDecoration(); 
      }
  },
  methods: {
    getItemPrice(item) { return item.cashPrice || item.price || item.cash || 0; },
    
    handleKeydown(e) {
        if (this.subMode === 'decorate_item' || this.subMode === 'equipment_item') {
            if (e.key === 'ArrowLeft') this.prevItem();
            if (e.key === 'ArrowRight') this.nextItem();
        }
        if (this.subMode === 'decorate_cat' || this.subMode === 'equipment_cat') {
            if (e.key === 'ArrowLeft') this.scrollLeftCat();
            if (e.key === 'ArrowRight') this.scrollRightCat();
        }
    },
    
    goToShop() { this.$store.dispatch('selectTab', 'shop'); this.subMode = 'list'; },
    onHorseHover(horse) {
        if (this.currentTab === 'owned') { this.previewMyHorse(horse); } 
        else if (this.currentTab === 'shop' && horse.colors) { this.previewHorse(Object.keys(horse.colors)[0]); }
    },
    enterMode(mode) { this.$store.dispatch('selectTab', mode); this.viewMode = 'content'; this.subMode = 'list'; },
    
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
                this.previewMyHorse(this.selectedHorse); // Reset preview to original horse
                return;
            }
            if (this.subMode === 'actions') {
                this.subMode = 'list';
                this.$store.dispatch('selectHorse', null);
                return;
            }
        }
        this.goHome();
    },
    goHome() {
      this.viewMode = 'home';
      this.$store.dispatch('selectHorse', null);
      api.post("loadHorse", { horseModel: 'CLEAR' });
    },
    openHorseCargo() {
        if (!this.selectedHorse || !this.selectedHorse.id) return;
        // เรียก Event ไปยัง backend (Lua) เพื่อเปิด UI กระเป๋า
        api.post("OpenHorseCargo", { horseId: this.selectedHorse.id });
        
        // ปิดเมนู Stable ทันทีหลังจากเปิดกระเป๋า
        this.closeMenu(); 
    },
    selectHorse(horse) {
      this.$store.dispatch('selectHorse', horse);
      if (this.currentTab === 'owned') { this.subMode = 'actions'; }
    },
    getHorseName(horse) { return horse.name || horse.breed || "Unknown Horse"; },
    getBondingLevel(xp) { if (xp >= 2400) return 4; if (xp >= 1700) return 3; if (xp >= 900) return 2; return 1; },
    getSelectedPrice() { return (this.selectedHorse && this.selectedHorse.colors && this.selectedColorModel) ? this.selectedHorse.colors[this.selectedColorModel].cashPrice : 0; },
    closeMenu() {
      api.post("CloseStable", { MenuAction: "Close" });
      this.$store.dispatch('closeDashboard');
      setTimeout(() => { this.viewMode = 'home'; this.subMode = 'list'; }, 500);
    },
    previewHorse(modelName) { api.post("loadHorse", { horseModel: modelName }); },
    previewMyHorse(horse) { api.post("loadMyHorse", { HorseModel: horse.model, HorseComp: horse.components, HorseId: horse.id, HorseGender: horse.gender }); },
    
    // --- CATEGORY & NAVIGATION LOGIC ---
    openDecorateCategories() {
        api.post("selectHorse", { horseId: this.selectedHorse.id });
        this.subMode = 'decorate_cat'; this.scrollOffsetCat = 0;
    },
    // [NEW] เปิดเมนูจัดการอุปกรณ์ (Owned)
    manageEquipment() {
        api.post("selectHorse", { horseId: this.selectedHorse.id });
        this.subMode = 'equipment_cat'; this.scrollOffsetCat = 0;
    },
    scrollLeftCat() { if (this.scrollOffsetCat > 0) this.scrollOffsetCat--; },
    scrollRightCat() { 
        const list = (this.subMode === 'equipment_cat') ? this.ownedCategories : this.decorCategoryList;
        if (this.scrollOffsetCat + 6 < list.length) this.scrollOffsetCat++;
    },
    
    openDecorateItems(category) {
        this.selectedDecorCategory = category; this.currentDecorIndex = 0; this.subMode = 'decorate_item'; this.previewDecoration();
    },
    openEquipmentItems(category) {
        this.selectedDecorCategory = category; this.currentDecorIndex = 0; this.subMode = 'equipment_item';
        // ไม่ต้อง Preview เพราะจะโชว์ของที่มีอยู่แล้ว
    },
    
    nextItem() {
        if (this.currentDecorIndex < this.currentCategoryItems.length - 1) this.currentDecorIndex++;
        else this.currentDecorIndex = 0;
    },
    prevItem() {
        if (this.currentDecorIndex > 0) this.currentDecorIndex--;
        else this.currentDecorIndex = this.currentCategoryItems.length - 1;
    },
    
    previewDecoration() {
        const item = this.currentDecorItem;
        const price = this.getItemPrice(item);
        if (item && item.hash) { api.post(this.selectedDecorCategory, { hash: item.hash, price: price, id: 0 }); }
    },
    
    buyDecoration() {
        const item = this.currentDecorItem;
        if (!item || !item.hash) return;
        const cashCost = item.cashPrice || item.price || 0;
        const goldCost = item.goldPrice || 0;
        
        // 1. Preview
        api.post(this.selectedDecorCategory, { hash: item.hash, price: cashCost, id: 0 });
        
        // 2. Buy & Save Equipped
        api.post("CloseStable", { MenuAction: "save", cashPrice: cashCost, goldPrice: goldCost, currencyType: 0 });
        
        // 3. [IMPORTANT] Save Ownership Record
        api.post("horseAction", { action: 'saveOwned', horseId: this.selectedHorse.id, componentHash: item.hash });
        
        setTimeout(() => this.closeMenu(), 500);
    },

    // --- EQUIPMENT MANAGEMENT HELPER ---
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
    toggleEquip(hash, equip) {
        if (equip) {
            // ใส่ของ (ใช้ระบบใส่ของที่มีอยู่แล้ว ไม่เสียเงิน)
            api.post("horseAction", { action: 'equipOwned', horseId: this.selectedHorse.id, componentHash: hash });
        } else {
            // ถอดของ
            api.post("horseAction", { action: 'unequipOne', horseId: this.selectedHorse.id, componentHash: hash });
        }
        setTimeout(() => this.closeMenu(), 300);
    },

    formatCategoryName(name) { return name ? name.replace(/([A-Z])/g, ' $1').trim() : ''; },
    isSelected(horse) { return this.selectedHorse && ((this.currentTab === 'owned' && this.selectedHorse.id === horse.id) || (this.currentTab === 'shop' && this.selectedHorse.breed === horse.breed)); },
    
    performAction(action) {
        if (!this.selectedHorse) return;
        if (action === 'decorate') { this.openDecorateCategories(); return; }
        api.post("horseAction", { action: action, horseId: this.selectedHorse.id, horseModel: this.selectedHorse.model });
        if (['call', 'return', 'release'].includes(action)) this.closeMenu();
        if (['heal', 'setMain'].includes(action)) setTimeout(() => this.closeMenu(), 300);
    },
    
    buyHorse() {
        if(!this.selectedColorModel) return;
        api.post("BuyHorse", { ModelH: this.selectedColorModel, name: this.newHorseName, currencyType: "cash", isTrainer: false });
        setTimeout(() => this.closeMenu(), 500);
    }
  }
};
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Pridi:wght@300;400;500;600;700&display=swap');
* { font-family: 'Pridi', serif !important; }
.dashboard-container { display: flex; width: 100vw; height: 100vh; position: relative; color: #f0f0f0; }
.flat-panel { background: rgba(15, 15, 15, 0.96); border: 1px solid rgba(255, 255, 255, 0.05); border-radius: 4px; }

/* Status Badge (New) */
.status-badge { padding: 5px 15px; border-radius: 4px; font-size: 12px; font-weight: bold; letter-spacing: 1px; margin-bottom: 10px; }
.status-badge.equipped { background: rgba(46, 204, 113, 0.2); color: #2ecc71; border: 1px solid #2ecc71; }
.status-badge.stored { background: rgba(255, 255, 255, 0.1); color: #aaa; border: 1px solid #666; }

.btn-danger { background: #c0392b; color: #fff; box-shadow: none !important; }
.btn-danger:hover { background: #e74c3c; box-shadow: none !important; }

.empty-notif { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; color: #888; }
.empty-notif h2 { color: #fff; font-size: 24px; margin-bottom: 10px; }

/* ... Styles เดิม ... */
.carousel-container { position: absolute; bottom: 80px; left: 50%; transform: translateX(-50%); display: flex; flex-direction: column; align-items: center; gap: 10px; z-index: 20; }
.carousel-container-wide { position: absolute; bottom: 100px; left: 50%; transform: translateX(-50%); display: flex; flex-direction: row; align-items: center; gap: 20px; z-index: 20; }
.decor-grid-6 { display: flex; gap: 15px; }
.nav-arrow { background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); color: #fff; width: 50px; height: 50px; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 24px; transition: 0.2s; font-family: Arial, sans-serif !important; }
.nav-arrow:hover { background: #fff; color: #000; transform: scale(1.1); }
.decor-selector-center { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; text-align: center; text-shadow: 0 2px 5px rgba(0,0,0,0.8); }
.decor-item-name { font-size: 42px; margin: 0; font-weight: 600; color: #fff; letter-spacing: 1px; }
.decor-nav-row { display: flex; align-items: center; gap: 15px; font-size: 16px; color: #ddd; }
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
.sidebar { width: 360px; height: 85%; margin: auto 0 auto 60px; display: flex; flex-direction: column; padding: 25px; }
.sidebar-header { margin-bottom: 20px; }
.stable-title { font-size: 20px; margin: 0; color: #fff; font-weight: 600; text-transform: uppercase; letter-spacing: 1px; }
.horse-list-wrapper { flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 8px; padding-top: 10px; }
.horse-card { display: flex; align-items: center; background: rgba(255,255,255,0.02); padding: 12px 15px; border-radius: 4px; border-left: 3px solid transparent; cursor: pointer; transition: 0.2s; }
.horse-card:hover { background: rgba(255,255,255,0.04); }
.horse-card.selected { background: rgba(255,255,255,0.07); border-left-color: #fff; }
.card-icon { width: 36px; height: 36px; margin-right: 15px; display: flex; align-items: center; justify-content: center; background: rgba(255,255,255,0.03); border-radius: 50%; }
.card-info h3 { font-size: 15px; margin: 0; font-weight: 500; color: #eee; }
.card-info p { font-size: 12px; color: #666; margin: 0; }
.price-text { color: #fff; font-weight: 600; font-size: 13px; }
.details-panel { position: absolute; right: 60px; bottom: 60px; width: 340px; padding: 30px; }
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
  position: absolute;
  top: 40%;           /* อยู่กึ่งกลางในแนวตั้ง */
  left: 80px;         /* เว้นระยะจากขอบซ้าย 60px (ให้ตรงกับแนวปุ่มเมนูอื่นๆ) */
  transform: translateY(-50%); /* ขยับขึ้น 50% ของความสูงตัวเองเพื่อให้กลางเป๊ะ */
  width: 320px;       /* ปรับขนาดความกว้างตามต้องการ */
  z-index: 20;
}
.manage-info-right {
  position: absolute;
  top: 40%;      /* ระดับความสูงเดียวกับฝั่งซ้าย (ปรับเลขนี้ตามที่แก้ในฝั่งซ้าย) */
  right: 80px;   /* ชิดขวา 60px */
  transform: translateY(-50%);
  width: 320px;
  z-index: 20;
}
</style>