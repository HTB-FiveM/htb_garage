<template>
  <button class="custom-button">
    <slot>{{ label }}</slot>
  </button>
</template>

<script setup lang="ts">
defineProps<{ label?: string }>();
</script>

<style scoped lang="scss">
.custom-button {
  padding: 0.5rem 1rem;
  background: #2d2d2d;
  color: white;
  border: 1px solid #666;
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
}
.custom-button:hover {
  background: #3a3a3a;
}
</style>
