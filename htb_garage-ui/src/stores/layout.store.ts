import { defineStore } from 'pinia';
import { ref } from 'vue';
import type { JSX } from 'vue/jsx-runtime';

export const useLayoutStore = defineStore('layout', () => {
  const headerContent = ref<null | (() => JSX.Element)>(null);

  function setHeader(content: null | (() => JSX.Element)) {
    headerContent.value = content;
  }

  return { headerContent, setHeader };
});
