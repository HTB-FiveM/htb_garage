<script setup lang="ts">
import { computed } from "vue";

const props = defineProps<{ barColour: string, label: string, value: number, percentage: number}>()

const progressBarStyle = computed(() => {
  return {
    width: props.value + '%',
    backgroundColor: props.barColour, // Use the 'barColor' prop to set the color
  };
});

</script>

<template>
  <div class="container">
    <div class="header">
      <small>{{ label }}</small>
      <small class="value">{{ value }}%</small>
    </div>
    <div class="progress-bar-background">
      <div class="progress-bar-fill" :style="progressBarStyle"></div>
    </div>
  </div>
</template>

<style scoped>
.container {
  width: 100%; /* Fills the width of the parent div */
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 5px; /* Adjust as needed for spacing between the rows */
}

.value {
  float: right;
}

.progress-bar-background {
  height: 2px; /* Thin line as specified */
  background-color: #eee; /* Light grey background for the progress bar */
  width: 100%;
}

.progress-bar-fill {
  height: 2px; /* Ensures the fill matches the height of the background */
}

.progress-bar {
  display: -ms-flexbox;
  display: flex;
  -ms-flex-direction: column;
  flex-direction: column;
  -ms-flex-pack: center;
  justify-content: center;
  overflow: hidden;
  color: #fff;
  text-align: center;
  white-space: nowrap;
  background-color: #007bff;
  transition: width 0.6s ease;
}

.bg-warning {
  background-color: #ffc107 !important;
}

.bg-danger {
  background-color: #dc3545 !important;
}
</style>
