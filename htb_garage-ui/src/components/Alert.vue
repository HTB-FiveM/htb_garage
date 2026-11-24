<script lang="ts" setup>
// Pre-defined variants and their icons
const VARIANT_ICONS: Record<string, string> = {
  success: '✓',
  warning: '⚠️',
  error: '✖',
};

// Define props
const props = defineProps<{
  /** Variant style: success (green), warning (yellow), or error (red) */
  variant?: 'success' | 'warning' | 'error';
  /** Fallback message if slot is not used */
  message?: string;
}>();

// Determine variant, defaulting to 'warning'
const variant = props.variant ?? 'warning';
// Compute icon and CSS class
const icon = VARIANT_ICONS[variant];
const variantClass = `wi-${variant}`;
</script>

<template>
  <div :class="['warning-indicator', variantClass]">
    <span class="icon">{{ icon }}</span>
    <span class="message"
      ><slot>{{ message }}</slot></span
    >
  </div>
</template>

<style scoped>
.warning-indicator {
  display: inline-flex;
  align-items: center;
  padding: 0.5rem 1rem;
  border-radius: 0.25rem;
  font-family: inherit;
  font-size: 1rem;
}
.warning-indicator .icon {
  margin-right: 0.5rem;
  font-size: 1.25em;
}

/* Success (green) */
.wi-success {
  background-color: rgba(40, 167, 69, 0.1);
  color: #28a745;
  border: 1px solid #28a745;
}
/* Warning (yellow/orange) */
.wi-warning {
  background-color: rgba(255, 193, 7, 0.1);
  color: #ffc107;
  border: 1px solid #ffc107;
}
/* Error (red) */
.wi-error {
  background-color: rgba(220, 53, 69, 0.1);
  color: #dc3545;
  border: 1px solid #dc3545;
}
</style>
