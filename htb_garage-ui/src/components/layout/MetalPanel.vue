<script setup lang="ts">
import { useRouter } from 'vue-router';
const router = useRouter();
const close = () => router.push('/');
</script>

<template>
  <div class="metal-panel">
    <div class="panel-header">
      <div class="header-left">
        <div class="header-slot">
          <slot name="header" />
        </div>
      </div>
      <button class="close-button" @click="close">×</button>
    </div>

    <div class="panel-content">
      <slot />
    </div>
  </div>
</template>

<style scoped lang="scss">
.metal-panel {
  background: rgba(25, 25, 25, 0.75);
  border: 1px solid #444;
  border-radius: 12px;
  padding: 20px;
  min-width: 400px;
  box-shadow:
    inset 0 1px 1px rgba(255, 255, 255, 0.1),
    0 4px 10px rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(6px);
  position: relative;
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  min-height: 48px;
  padding: 0 10px;
  background: rgba(74, 74, 74, 0.75);
}
.header-left {
  flex: 1;
  display: flex;
  align-items: center;
}
.header-slot {
  flex: 1; /* ← THIS makes the search input fill horizontally */
  display: flex;
  align-items: center;
}

.header-slot > * {
  flex: 1; /* ← THIS ensures whatever is injected (like SearchInput) fills it */
}
.close-button {
  background: #2c2c2c;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 1.2rem;
  width: 36px;
  height: 36px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-left: 10px; /* space between search and close button */
}
.panel-content {
  margin-top: 10px;
}
</style>
