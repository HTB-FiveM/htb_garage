<template>
  <div class="autocomplete">
    <input type="text" v-model="query" @input="filter" :placeholder="placeholder" />
    <ul v-if="filtered.length">
      <li v-for="opt in filtered" :key="opt" @click="select(opt)">
        {{ opt }}
      </li>
    </ul>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';

const props = defineProps<{ modelValue: string; options: string[]; placeholder?: string }>();
const emit = defineEmits(['update:modelValue']);

const query = ref(props.modelValue);
const filtered = ref<string[]>([]);

watch(
  () => props.modelValue,
  (val) => (query.value = val),
);

function filter() {
  filtered.value = props.options.filter((opt) => opt.toLowerCase().includes(query.value.toLowerCase()));
}

function select(opt: string) {
  emit('update:modelValue', opt);
  filtered.value = [];
}
</script>

<style scoped lang="scss">
.autocomplete {
  position: relative;
}
input {
  width: 100%;
  padding: 0.5rem;
  background: #111;
  color: white;
  border: 1px solid #444;
  border-radius: 6px;
}
ul {
  position: absolute;
  width: 100%;
  background: #1a1a1a;
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid #333;
  border-radius: 4px;
  z-index: 10;
}
li {
  padding: 0.5rem;
  cursor: pointer;
}
li:hover {
  background: #333;
}
</style>
