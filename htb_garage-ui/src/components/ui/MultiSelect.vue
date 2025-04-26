<template>
  <div class="multi-select">
    <div class="selected-items">
      <span v-for="(item, idx) in modelValue" :key="idx" class="tag" @click="$emit('remove', item)"> {{ item }} ✕ </span>
    </div>
    <select @change="add">
      <option disabled value="">Add tag...</option>
      <option v-for="option in options" :key="option" :value="option">{{ option }}</option>
    </select>
  </div>
</template>

<script setup lang="ts">
defineProps<{ modelValue: string[]; options: string[] }>();
const emit = defineEmits(['remove', 'add']);

function add(event: Event) {
  const value = (event.target as HTMLSelectElement).value;
  if (value) {
    (event.target as HTMLSelectElement).selectedIndex = 0;
    emit('add', value);
  }
}
</script>

<style scoped lang="scss">
.multi-select {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.selected-items {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.tag {
  background: #333;
  padding: 0.3rem 0.6rem;
  border-radius: 12px;
  font-size: 0.85rem;
  cursor: pointer;
}
select {
  padding: 0.5rem;
  background: #111;
  color: white;
  border: 1px solid #444;
  border-radius: 6px;
}
</style>
