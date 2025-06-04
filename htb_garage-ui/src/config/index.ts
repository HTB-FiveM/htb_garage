export interface AppConfig {
    locale: string,
    fallbackLocale?: string,
    currency: string,
    maxFractionDigits: number
}
  
export const config: AppConfig = {
    locale: 'fr',
    fallbackLocale: 'en',
    currency: 'AUD',
    maxFractionDigits: 0
}
