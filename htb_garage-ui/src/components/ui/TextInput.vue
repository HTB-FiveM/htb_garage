<template>
  <div class="form-control">
    <label v-if="label">{{ label }}</label>
    <input
      type="text"
      :value="modelValue"
      @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      :class="{ error: error }"
    />
    <span v-if="error" class="error">{{ error }}</span>
  </div>
</template>

<script setup lang="ts">
defineProps<{ modelValue: string; label?: string; error?: string }>();
defineEmits(['update:modelValue']);
</script>

<style scoped lang="scss">
.form-control {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-bottom: 1rem;
}
input {
  padding: 0.5rem;
  background: #111;
  border: 1px solid #444;
  border-radius: 6px;
  color: white;
  outline: none;
}
input:focus {
  box-shadow: 0 0 6px 2px rgba(0, 100, 255, 0.75);
}
.error {
  color: red;
  font-size: 0.8rem;
}
</style>
