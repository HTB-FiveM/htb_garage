<template>
  <form class="metal-form" @submit.prevent="$emit('submit')">
    <slot />
  </form>
</template>

<script setup lang="ts">
defineEmits(['submit']);
</script>

<style scoped lang="scss">
.metal-form {
  background: rgba(25, 25, 25, 0.65);
  padding: 1.5rem;
  border-radius: 12px;
  border: 1px solid #444;
  box-shadow: inset 0 0 6px #000;
}
</style>
