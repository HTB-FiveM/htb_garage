<template>
  <div>
    <select :value="modelValue" @change="onChange">
      <option disabled value="">Select an option</option>
      <option v-for="option in options" :key="option" :value="option">{{ option }}</option>
    </select>
  </div>
</template>

<script setup lang="ts">
defineProps<{ modelValue: string; options: string[] }>();
const emit = defineEmits(['update:modelValue']);

const onChange = (event: Event) => {
  const select = event.target as HTMLSelectElement;
  emit('update:modelValue', select.value);
};
</script>

<style scoped lang="scss">
select {
  width: 100%;
  padding: 0.5rem;
  background: #111;
  color: white;
  border: 1px solid #444;
  border-radius: 6px;
}
select:focus {
  box-shadow: 0 0 6px 2px rgba(0, 100, 255, 0.75);
  outline: none;
}
</style>
