<template>
  <div class="group">
    <div v-for="option in options" :key="option.value" class="item">
      <label>
        <input :type="type" :value="option.value" v-model="model" />
        {{ option.label }}
      </label>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  modelValue: string | string[];
  options: { label: string; value: string }[];
  type: 'checkbox' | 'radio';
}>();
const emit = defineEmits(['update:modelValue']);

const model = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
});
</script>

<style scoped lang="scss">
.group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.item label {
  color: white;
  font-size: 0.9rem;
}
</style>
