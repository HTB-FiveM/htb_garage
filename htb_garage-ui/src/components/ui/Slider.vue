<template>
  <input
    type="range"
    :min="min"
    :max="max"
    :step="step"
    :value="modelValue"
    @input="$emit('update:modelValue', ($event.target as HTMLInputElement).valueAsNumber)"
  />
</template>

<script setup lang="ts">
defineProps<{ modelValue: number; min?: number; max?: number; step?: number }>();
defineEmits(['update:modelValue']);
</script>

<style scoped lang="scss">
input[type='range'] {
  width: 100%;
  height: 6px;
  background: #444;
  border-radius: 3px;
  appearance: none;
}
input[type='range']::-webkit-slider-thumb {
  appearance: none;
  background: #ccc;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 2px solid white;
  margin-top: -7px;
  background-image: radial-gradient(circle at center, #aaa 30%, #333 100%);
}
input[type='range']:focus::-webkit-slider-thumb {
  box-shadow: 0 0 8px 2px rgba(0, 100, 255, 0.75);
}
</style>
