import { createI18n, type I18nOptions } from 'vue-i18n';

/**
 * Wrapper around createI18n so you can pass a full options object.
 */
export function setupI18n(opts: I18nOptions) {
    return createI18n({
      // ensure Composition-API mode
      legacy: opts.legacy ?? false,

      // allow using $t or t() globally
      globalInjection: opts.globalInjection ?? false,

      // these must come from your opts
      locale:         opts.locale!,
      fallbackLocale: opts.fallbackLocale!,

      // messages object mapping locale → messages
      messages:       opts.messages!
    })
  }
