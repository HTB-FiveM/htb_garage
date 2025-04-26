<template>
  <div class="alert" :class="type">
    <slot />
  </div>
</template>

<script setup lang="ts">
defineProps<{ type?: 'info' | 'success' | 'error' }>();
</script>

<style scoped lang="scss">
.alert {
  padding: 0.75rem;
  border-radius: 6px;
  margin-bottom: 1rem;
  border: 1px solid white;
  background: rgba(255, 255, 255, 0.05);
}
.alert.success {
  border-color: #00ff88;
}
.alert.error {
  border-color: #ff0044;
}
</style>
