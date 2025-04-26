<template>
  <div class="expandable-item">
    <div class="header" @click="toggle">
      <slot name="header" />
    </div>
    <transition name="expand">
      <div class="details" v-show="expanded">
        <slot name="detail" />
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
const props = defineProps<{ open?: boolean }>();
const expanded = ref(false);

onMounted(() => {
  if (props.open) expanded.value = true;
});

const toggle = () => (expanded.value = !expanded.value);
</script>

<style scoped lang="scss">
.expandable-item {
  border-top: 1px solid rgba(255, 255, 255, 0.05);
}
.header {
  cursor: pointer;
}
.details {
  background: rgba(0, 0, 0, 0.3);
}
.expand-enter-active,
.expand-leave-active {
  transition: all 0.3s ease;
}
.expand-enter-from,
.expand-leave-to {
  opacity: 0;
  max-height: 0;
  overflow: hidden;
}
.expand-enter-to,
.expand-leave-from {
  opacity: 1;
  max-height: 400px;
}
</style>
