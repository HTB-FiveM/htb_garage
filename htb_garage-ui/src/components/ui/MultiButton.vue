<template>
  <div class="multi-button">
    <button
      v-for="(btn, index) in buttons"
      :key="index"
      :class="{ active: btn.value === modelValue }"
      @click="$emit('update:modelValue', btn.value)"
    >
      {{ btn.label }}
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{ buttons: { label: string; value: string }[]; modelValue: string }>();
defineEmits(['update:modelValue']);
</script>

<style scoped lang="scss">
.multi-button {
  display: flex;
}
.multi-button button {
  border: 1px solid #444;
  background: #222;
  color: white;
  padding: 0.5rem 1rem;
  cursor: pointer;
}
.multi-button button + button {
  border-left: none;
}
.multi-button button.active {
  background: #0af;
}
</style>
