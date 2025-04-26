// eslint-disable-next-line vue/multi-word-component-names
<script lang="ts" setup>
import { useAttrs, computed } from 'vue';

/** Button variants */
type Variant = 'primary' | 'secondary' | 'danger' | 'outline';

/** Button sizes */
type Size = 'sm' | 'md' | 'lg';

interface Props {
  type?: 'button' | 'submit' | 'reset';
  variant?: Variant;
  size?: Size;
  disabled?: boolean;
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (e: 'click', event: MouseEvent): void;
}>();

const attrs = useAttrs();

// Compute variant and size classes
const variantClass = computed(() => {
  switch (props.variant) {
    case 'secondary':
      return 'btn-secondary';
    case 'danger':
      return 'btn-danger';
    case 'outline':
      return 'btn-outline';
    default:
      return 'btn-primary';
  }
});

const sizeClass = computed(() => {
  switch (props.size) {
    case 'sm':
      return 'btn-sm';
    case 'lg':
      return 'btn-lg';
    default:
      return 'btn-md';
  }
});

function onClick(e: MouseEvent) {
  if (!props.disabled) {
    emit('click', e);
  }
}
</script>

<template>
  <button :type="type" :disabled="disabled" @click="onClick" v-bind="attrs" :class="['btn', variantClass, sizeClass]">
    <slot />
  </button>
</template>

<style scoped>
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: none;
  border-radius: 0.25rem;
  font-family: inherit;
  cursor: pointer;
  transition:
    box-shadow 0.3s ease,
    background-color 0.2s ease;
  position: relative;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Sizes */
.btn-sm {
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
}
.btn-md {
  padding: 0.5rem 1rem;
  font-size: 1rem;
}
.btn-lg {
  padding: 0.75rem 1.5rem;
  font-size: 1.125rem;
}

/* Variants */
.btn-primary {
  background-color: #259d44;
  color: #fff;
}
.btn-secondary {
  background-color: #6c757d;
  color: #fff;
}
.btn-danger {
  background-color: #dc3545;
  color: #fff;
}
.btn-outline {
  background-color: transparent;
  color: #1c1f24;
  border: 1px solid #1c1f24;
}

/* Hover */
.btn:not(:disabled):hover {
  filter: brightness(1.1);
}

.btn-outline:not(:disabled):hover {
  background-color: rgba(30, 72, 86, 0.1);
}

/* Focus glow */
.btn:focus {
  outline: none;
  box-shadow:
    0 0 0 2px rgba(30, 72, 86, 0.9),
    0 0 8px 4px rgba(30, 72, 86, 0.3);
}
</style>
