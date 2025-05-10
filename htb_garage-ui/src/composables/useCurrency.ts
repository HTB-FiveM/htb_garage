import { computed, unref, inject, type Ref } from 'vue'
import type { AppConfig } from "@/config";


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
  opts?: {
    locale: string,
    currency: string,
    decimals: number
  }
) {
  const config = inject<AppConfig>('appConfig', {
    locale: 'en-AU',
    currency: 'AUD',
    maxFractionDigits: 0
  });

  // Use opts, then config, then hard-coded defaults
  const locale   = opts?.locale   ?? config.locale
  const currency = opts?.currency ?? config.currency
  const decimals = opts?.decimals ?? config.maxFractionDigits

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