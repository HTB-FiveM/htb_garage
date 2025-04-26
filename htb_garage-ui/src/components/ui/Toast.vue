<template>
  <div v-if="visible" class="toast">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

const props = defineProps<{ timeout?: number }>();
const visible = ref(true);

onMounted(() => {
  setTimeout(() => (visible.value = false), props.timeout ?? 3000);
});
</script>

<style scoped lang="scss">
.toast {
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  background: #222;
  color: white;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  border: 1px solid white;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.7);
  z-index: 9999;
}
</style>
