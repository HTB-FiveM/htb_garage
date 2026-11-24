<template>
  <div class="text-input-wrapper">
    <input
      v-if="!multiline"
      class="text-input"
      :type="type"
      :value="modelValue ?? ''"
      :placeholder="placeholder"
      :id="id"
      :name="name"
      :disabled="disabled"
      :maxlength="maxLength"
      @input="onInput"
    />

    <textarea
      v-else
      class="text-area"
      :value="modelValue ?? ''"
      :placeholder="placeholder"
      :id="id"
      :name="name"
      :disabled="disabled"
      :maxlength="maxLength"
      :rows="calculatedRows"
      @input="onInput"
    />

    <div v-if="multiline && showCharacterCount" class="char-counter">{{ currentLength }} / {{ maxLength }}</div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  modelValue: string | null | undefined;
  placeholder?: string;
  type?: string;
  id?: string;
  name?: string;
  disabled?: boolean;
  maxLength?: number;
  multiline?: boolean;
  maxLines?: number;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', value: string | null): void;
}>();

function onInput(e: Event) {
  const val = (e.target as HTMLInputElement | HTMLTextAreaElement).value;
  emit('update:modelValue', val === '' ? null : val);
}

const currentLength = computed(() => (props.modelValue ?? '').length);

const calculatedRows = computed(() => {
  return props.maxLines ?? 4; // Default 4 lines if maxLines not provided
});

const showCharacterCount = computed(() => {
  return props.maxLength !== undefined && props.multiline;
});
</script>

<style scoped lang="scss">
.text-input-wrapper {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.text-input,
.text-area {
  padding: 0.5rem;
  background: #111;
  border: 1px solid #444;
  border-radius: 6px;
  color: white;
  outline: none;
  font-size: 1rem;
  width: 100%;
  box-sizing: border-box;
  transition: all 0.2s ease;
  font-family: inherit;
  resize: vertical;
  min-height: 36px;
}

.text-input:focus,
.text-area:focus {
  box-shadow: 0 0 6px 2px rgba(0, 100, 255, 0.75);
}

.char-counter {
  margin-top: 0.25rem;
  font-size: 0.8rem;
  color: #bbb;
  text-align: right;
}

.text-input:disabled,
.text-area:disabled {
  background-color: #333;
  cursor: not-allowed;
}
</style>
