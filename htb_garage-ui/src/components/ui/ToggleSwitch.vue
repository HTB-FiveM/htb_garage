<template>
  <label class="switch">
    <input type="checkbox" :checked="modelValue" @change="$emit('update:modelValue', ($event.target as HTMLInputElement).checked)" />
    <span class="slider"></span>
    <span class="label">{{ label }}</span>
  </label>
</template>

<script setup lang="ts">
defineProps<{ modelValue: boolean; label?: string }>();
defineEmits(['update:modelValue']);
</script>

<style scoped lang="scss">
.switch {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
}
.slider {
  position: relative;
  width: 40px;
  height: 20px;
  background: #444;
  border-radius: 10px;
  cursor: pointer;
}
.slider::after {
  content: '';
  position: absolute;
  left: 2px;
  top: 2px;
  width: 16px;
  height: 16px;
  background: #ccc;
  border-radius: 50%;
  transition: 0.2s;
}
input:checked + .slider::after {
  transform: translateX(20px);
  background: #0af;
}
input {
  display: none;
}
.label {
  color: white;
}
</style>
