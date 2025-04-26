<script setup lang="ts">
import { useRouter } from 'vue-router';
const router = useRouter();
const close = () => router.push('/');
</script>

<template>
  <div class="metal-panel">
    <button class="close-button" @click="close">×</button>
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
.close-button {
  position: absolute;
  top: 10px;
  right: 10px;
  background: #2c2c2c;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 1.2rem;
  width: 32px;
  height: 32px;
  cursor: pointer;
}
.panel-content {
  margin-top: 40px;
}
</style>
