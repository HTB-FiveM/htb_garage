import { ref } from 'vue';
import { defineStore } from 'pinia';
import type { VNode } from 'vue';

export const useLayoutStore = defineStore('layout', () => {
  const headerContent = ref<(() => VNode | null) | null>(null);

  function setHeader(content: (() => VNode | null) | null) {
    headerContent.value = content;
  }

  function clearHeader() {
    headerContent.value = null;
  }

  return {
    headerContent,
    setHeader,
    clearHeader,
  };
});
