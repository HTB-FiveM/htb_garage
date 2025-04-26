<template>
  <div class="vehicle-search-panel">
    <MetalForm @submit="submitForm">
      <div class="header-bar">
        <span class="title">Vehicle Search</span>
        <div class="search-input">
          <SearchInput v-model="search" placeholder="Search by plate or name" />
        </div>
        <button class="close-button" @click="clearSearch">×</button>
      </div>

      <div class="form-body">
        <Label>Vehicle Type</Label>
        <SingleSelect v-model="vehicleType" :options="vehicleTypes" />

        <Label>Tags</Label>
        <MultiSelect v-model="tags" :options="availableTags" @remove="removeTag" @add="addTag" />

        <Label>Performance Level</Label>
        <Slider v-model="performanceLevel" :min="0" :max="100" :step="1" />

        <Label>Options</Label>
        <CheckRadioGroup type="checkbox" v-model="optionsSelected" :options="availableOptions" />

        <Button label="Submit Search" />
      </div>

      <Alert v-if="errorMessage" type="error">{{ errorMessage }}</Alert>
      <Toast v-if="toastMessage" :timeout="3000">{{ toastMessage }}</Toast>

      <div v-for="(veh, index) in filteredVehicles" :key="index">
        <ExpandableListItem :open="veh.expanded">
          <template #header>
            <div class="vehicle-item-header" :class="{ highlighted: veh.expanded }">
              <strong>{{ veh.label }}</strong>
            </div>
          </template>
          <template #detail>
            <div v-if="veh.details">
              <ul class="vehicle-stats">
                <li v-for="(detail, idx) in veh.details.split(', ')" :key="idx">{{ detail }}</li>
              </ul>
            </div>
          </template>
        </ExpandableListItem>
      </div>
    </MetalForm>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, h } from 'vue';
import SearchInput from '@/components/ui/TextInput.vue'; // SearchInput would be a wrapper if you want, otherwise just TextInput
import SingleSelect from '@/components/ui/SingleSelect.vue';
import MultiSelect from '@/components/ui/MultiSelect.vue';
import Slider from '@/components/ui/Slider.vue';
import CheckRadioGroup from '@/components/ui/CheckRadioGroup.vue';
import Button from '@/components/ui/Button.vue';
import MetalForm from '@/components/layout/MetalForm.vue';
import ExpandableListItem from '@/components/ui/ExpandableListItem.vue';
import Alert from '@/components/ui/Alert.vue';
import Toast from '@/components/ui/Toast.vue';
import Label from '@/components/ui/Label.vue';
import { useLayoutStore } from '@/stores/layout.store';

/////
import SearchInput1 from '@/components/ui/TextInput.vue';

const layoutStore = useLayoutStore();

// Set header control when this page is active
onMounted(() => {
  // layoutStore.setHeader(() => <SearchInput1 v-model="search" placeholder="Search vehicles..." />);
  layoutStore.setHeader(() =>
    h('div', { style: { marginTop: '.8rem' } }, [
      h(SearchInput1, {
        modelValue: search.value,
        'onUpdate:modelValue': (v: string) => (search.value = v),
        placeholder: 'Search vehicles...',
      }),
    ]),
  );
});

// Clear header when leaving page
onUnmounted(() => {
  layoutStore.setHeader(null);
});

/////

const search = ref('');
const vehicleType = ref('');
const tags = ref<string[]>([]);
const availableTags = ['Import', 'Exotic', 'Muscle', 'Classic'];
const performanceLevel = ref(50);
const optionsSelected = ref<string[]>([]);
const availableOptions = [
  { label: 'Nitrous Installed', value: 'nitrous' },
  { label: 'Bulletproof Tires', value: 'bulletproof' },
];

const errorMessage = ref('');
const toastMessage = ref('');

const vehicles = ref([
  { label: 'McLaren ABC123, Import', details: 'Acceleration 82, Max Speed 93, Braking 74', expanded: false },
  { label: 'Zentorno DEF456', details: 'Acceleration 82, Max Speed 93, Braking 74', expanded: true },
]);

const filteredVehicles = computed(() => {
  if (!search.value) return vehicles.value;
  return vehicles.value.filter((v) => v.label.toLowerCase().includes(search.value.toLowerCase()));
});

function removeTag(tag: string) {
  tags.value = tags.value.filter((t) => t !== tag);
}
function addTag(tag: string) {
  if (!tags.value.includes(tag)) {
    tags.value.push(tag);
  }
}

function clearSearch() {
  search.value = '';
}

function submitForm() {
  if (!vehicleType.value) {
    errorMessage.value = 'Please select a vehicle type.';
    return;
  }
  errorMessage.value = '';
  toastMessage.value = 'Search submitted!';
}

onMounted(() => {
  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (msg?.type === 'updateVehicles' && Array.isArray(msg.vehicles)) {
      vehicles.value = (msg.vehicles as VehicleMessage[]).map((v) => ({
        label: v.label,
        details: v.details,
        expanded: false,
      }));
    }
  });
});

interface VehicleMessage {
  label: string;
  details: string;
}

const vehicleTypes = ref([
  'Super',
  'Sports',
  'Muscle',
  'Sedan',
  'SUV',
  'Off-Road',
  'Motorcycle',
  'Compact',
  'Coupe',
  'Classic',
  'Utility',
  'Van',
  'Emergency',
  'Commercial',
  'Military',
]);
</script>

<style scoped lang="scss">
.vehicle-search-panel {
  background: rgba(15, 15, 15, 0.7);
  border-radius: 12px;
  border: 1px solid white;
  padding: 0;
  max-width: 600px;
  margin: 2rem auto;
  backdrop-filter: blur(8px);
  overflow: hidden;
}
.header-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: rgba(30, 30, 30, 0.95);
  padding: 0.75rem 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}
.header-bar .title {
  font-weight: bold;
  font-size: 1.2rem;
}
.search-input {
  flex: 1;
  margin: 0 1rem;
}
.header-bar .close-button {
  background: none;
  border: none;
  color: white;
  font-size: 1.3rem;
  cursor: pointer;
}
.form-body {
  padding: 1rem;
}
.vehicle-item-header {
  padding: 0.75rem 1rem;
}
.vehicle-item-header.highlighted {
  background: rgba(255, 255, 255, 0.05);
}
.vehicle-stats {
  list-style: none;
  margin: 0;
  padding: 0.5rem 1rem 1rem;
}
.vehicle-stats li {
  margin-bottom: 0.5rem;
}
</style>
