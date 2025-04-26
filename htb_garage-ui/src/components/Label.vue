// eslint-disable-next-line vue/multi-word-component-names
<script lang="ts" setup>
import { useAttrs } from 'vue';

// Define component props
type LabelProps = {
  labelFor?: string;
};

const { labelFor } = defineProps<LabelProps>();

const attrs = useAttrs();
</script>

<template>
  <label :for="labelFor" class="label" v-bind="attrs">
    <slot />
  </label>
</template>

<style scoped>
.label {
  display: block;
  margin-bottom: 0.25rem;
}
</style>
