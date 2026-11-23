<template>
  <input
    type="text"
    :id="id"
    :name="name"
    :disabled="disabled"
    :placeholder="placeholder"
    v-bind="attrs"
    class="currency-input"
    :value="displayValue"
    @input="onInput"
    @focus="onFocus"
    @blur="onBlur"
  />
</template>

<script lang="ts" setup>
import { ref, watch, useAttrs } from 'vue';

// Props
interface Props {
  /** Bound numeric value */
  modelValue: number | null | undefined;
  /** BCP 47 locale string (e.g. 'en-US', 'de-DE') */
  locale?: string;
  /** ISO currency code (e.g. 'USD', 'EUR') */
  currency?: string;
  /** Max decimal places */
  maxFractionDigits?: number;
  /** Input placeholder text */
  placeholder?: string;
  /** Input id */
  id?: string;
  /** Input name */
  name?: string;
  /** Disabled */
  disabled?: boolean;
}
const props = defineProps<Props>();
const emit = defineEmits<{
  (e: 'update:modelValue', value: number | null): void;
}>();
const attrs = useAttrs();

// Determine default locale per currency when none provided
function defaultLocaleForCurrency(curr: string): string {
  const map: Record<string,string> = {
    USD: 'en-US',
    EUR: 'en-IE',
    GBP: 'en-GB',
    JPY: 'ja-JP',
    AUD: 'en-AU',
    CAD: 'en-CA'
  };
  return map[curr.toUpperCase()] ?? navigator.language;
}

// Locale & formatting options
const currency = props.currency ?? 'USD';
// Use provided locale if non-empty; otherwise pick sensible default per currency
const locale = (props.locale && props.locale.trim()) ? props.locale : defaultLocaleForCurrency(currency);
const maxFractionDigits = props.maxFractionDigits ?? 2;

// Formatter for display, using currency style
const formatter = new Intl.NumberFormat(locale, {
  style: 'currency',
  currency,
  minimumFractionDigits: maxFractionDigits,
  maximumFractionDigits: maxFractionDigits
});

// Determine grouping & decimal separators
const parts = formatter.formatToParts(12345.6);
const groupSep = parts.find(p => p.type === 'group')?.value ?? ',';
const decimalSep = parts.find(p => p.type === 'decimal')?.value ?? '.';

// Internal state
const isFocused = ref(false);
const displayValue = ref('');

// Format raw number to localized currency string
function formatNumber(value: number | null | undefined): string {
  if (value === null || value === undefined || isNaN(value)) return '';
  return formatter.format(value);
}

// Sync display when modelValue changes (unless focused)
watch(
  () => props.modelValue,
  (val) => {
    if (!isFocused.value) {
      displayValue.value = formatNumber(val);
    }
  },
  { immediate: true }
);

// Handle user typing
function onInput(event: Event) {
  const raw = (event.target as HTMLInputElement).value;
  // Remove any currency and group separators
  let withoutGroup = raw.split(groupSep).join('');
  // Normalize decimal separator to dot
  const normalized = withoutGroup.replace(new RegExp(`\\${decimalSep}`, 'g'), '.');
  // Keep digits, dot, minus
  const cleaned = normalized.replace(/[^0-9.\-]/g, '');
  const num = cleaned === '' || cleaned === '-' ? null : parseFloat(cleaned);
  emit('update:modelValue', num);
  displayValue.value = raw;
}

// On focus, show numeric string without formatting
function onFocus() {
  isFocused.value = true;
  const val = props.modelValue;
  displayValue.value = val == null || isNaN(val) ? '' : String(val);
}

// On blur, reformat to localized currency string
function onBlur() {
  isFocused.value = false;
  displayValue.value = formatNumber(props.modelValue);
}
</script>

<style scoped>
.currency-input {
  padding: 0.5rem;
  border: 1px solid #ccc;
  border-radius: 0.25rem;
  font-size: 1rem;
  width: 100%;
  box-sizing: border-box;
  transition: box-shadow 0.3s ease;
  font-family: inherit;
}
.currency-input:focus {
  outline: none;
  box-shadow:
    0 0 0 2px rgba(30, 72, 86, 0.9),
    0 0 8px 4px rgba(30, 72, 86, 0.3);
}
.currency-input:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}
</style>
