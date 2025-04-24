import { computed, unref, type Ref } from 'vue'

/**
 * Formats a number (or Ref<number>) as currency.
 *
 * @param raw      — the number or Ref<number> to format
 * @param locale   — e.g. 'en-US'
 * @param currency — ISO currency code, e.g. 'USD'
 * @param decimals — how many decimal places to show (default = 0)
 */
export function useCurrency(
  raw: number | Ref<number>,
  locale = 'en-AU',
  currency = 'AUD',
  decimals = 0
) {
  return computed<string>(() => {
    const value = unref(raw) ?? 0
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency,
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(value)
  })
}