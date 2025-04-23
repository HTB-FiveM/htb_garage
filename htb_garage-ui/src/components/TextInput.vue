<script lang="ts" setup>
import { useAttrs, computed } from 'vue';

const props = defineProps<{
  modelValue: string | null | undefined;
  placeholder?: string;
  type?: string;
  id?: string;
  name?: string;
  disabled?: boolean;
  multiline?: boolean;
  maxLength?: number;
}>();

const currentLength = computed(() => (props.modelValue ?? '').length);

const emit = defineEmits<{
  /** Emitted when the input value changes */
  (e: 'update:modelValue', value: string | null): void;
}>();

// Collect any other attributes passed to the component
const attrs = useAttrs();

function onInput(e: Event) {
  const val = (e.target as HTMLInputElement).value
  // normalize empty string back to null if you want
  emit('update:modelValue', val === '' ? null : val)
}
</script>

<template>
    <textarea
      v-if="multiline"
      :value="modelValue ?? ''"
      @input="onInput"
      v-bind="attrs"
      :placeholder="placeholder"
      :id="id"
      :name="name"
      :disabled="disabled"
      :maxlength="maxLength"
      class="text-input"
    ></textarea>
    <div v-if="maxLength" class="char-counter">
      {{ currentLength }} / {{ maxLength }}
    </div>
    <input
      v-else
      :value="modelValue ?? ''"
      @input="onInput"
      v-bind="attrs"
      :placeholder="placeholder"
      :type="type"
      :id="id"
      :name="name"
      :disabled="disabled"
      :maxlength="maxLength"
      class="text-input"
    />
  </template>

<style scoped>
.text-input-wrapper {
  position: relative;
}

.text-input {
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 0.25rem;
  font-size: 1rem;
  width: 100%;
  box-sizing: border-box;
  transition: box-shadow 0.3s ease;
  font-family: inherit;
  resize: vertical;
}

.char-counter {
  margin-top: 0.25rem;
  font-size: 0.875rem;
  text-align: right;
}

.text-input:focus {
  outline: none;
  /* Dark metallic blue gradient glow */
  box-shadow:
    0 0 0 2px rgba(30, 72, 86, 0.9),
    0 0 8px 4px rgba(30, 72, 86, 0.3);
}

.text-input:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}
</style>
