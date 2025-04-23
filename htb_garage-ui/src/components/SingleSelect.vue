
  
<script lang="ts" setup>
import { useAttrs, computed } from 'vue';

export interface Option<T = unknown> {
    value: T;
    label: string;
}

// Define component props
interface SelectProps<T = unknown> {
    modelValue: T | null | undefined;
    options: Option<T>[];
    placeholder?: string;
    id?: string;
    name?: string;
    disabled?: boolean;
}

const props = defineProps<SelectProps>();
const attrs = useAttrs();

const emit = defineEmits<{
    (e: 'update:modelValue', value: unknown): void;
}>();

const selectedIndex = computed<string|number>(() => {
  const idx = props.options.findIndex(o => o.value === props.modelValue)
  return idx >= 0 ? idx : ''
})

function onChange(e: Event) {
    const sel = e.target as HTMLSelectElement
    const idx = Number(sel.value)         // the index you put into <option :value="idx">
    const val = props.options[idx]?.value // lookup original T here
    emit('update:modelValue', val)
}
</script>

<template>
    <select
      :value="selectedIndex"
      @change="onChange"
      v-bind="attrs"
      :id="id"
      :name="name"
      :disabled="disabled"
      class="select-input"
    >
        <option v-if="placeholder" disabled value="">
            {{ placeholder }}
            </option>
            <option
            v-for="(opt, idx) in options"
            :key="idx"
            :value="idx"
        >
        {{ opt.label }}
        </option>
    </select>
</template>

<style scoped>
.select-input {
    padding: 0.5rem;
    border: 1px solid #ccc;
    border-radius: 0.25rem;
    font-size: 1rem;
    width: 100%;
    box-sizing: border-box;
    transition: box-shadow 0.3s ease;
    font-family: inherit;
    background-color: #fff;
    appearance: none;
}

.select-input:focus {
outline: none;
/* Dark metallic blue gradient glow */
box-shadow:
    0 0 0 2px rgba(30, 72, 86, 0.9),
    0 0 8px 4px rgba(30, 72, 86, 0.3);
}

.select-input:disabled {
    background-color: #f5f5f5;
    cursor: not-allowed;
}
</style>
  