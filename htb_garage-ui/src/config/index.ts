export interface AppConfig {
    locale:          string
    currency:        string
    maxFractionDigits: number
}
  
export const config: AppConfig = {
    locale:           'en-AU',
    currency:         'AUD',
    maxFractionDigits: 0,
}
