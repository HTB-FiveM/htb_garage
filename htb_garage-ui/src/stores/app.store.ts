import type { AppStore } from '@/types/appTypes';
import { defineStore } from 'pinia';

export const useAppStore = defineStore('app', {
  state: () =>
    ({
      isVisible: false,
    }) as AppStore,
});
