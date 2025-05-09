<script lang="ts" setup>
import Label from "./Label.vue";
import TextInput from "./TextInput.vue";
import SingleSelect, { Option } from "./SingleSelect.vue";
import ToggleSwitch from "./ToggleSwitch.vue";

import { useImpoundStore } from "@/stores/impound.store";
import { computed } from "vue";

const store = useImpoundStore();

const availableImpounds = computed<Option<string>[]>(() => {
  if (!store.availableImpounds) return [];
  return store.availableImpounds.map(
    (x) =>
      ({
        label: x?.displayName,
        value: x?.id,
      } as Option<string>)
  );
});

const timePeriods = computed<Option<number>[]>(() => {
  if (!store.timePeriods) return [];
  return store.timePeriods.map(
    (x) =>
      ({
        label: x == 0 ? `${x} hours - Can take out immediately` : `${x} hours`,
        value: x,
      } as Option<number>)
  );
});
</script>

<template>
  <div class="field">
    <Label label-for="selectImpound">Select impound</Label>
    <SingleSelect
      id="selectImpound"
      name="selectImpound"
      :options="availableImpounds"
      v-model="store.storeVehicle!.impoundId"
    />
    <Label class="summarise"
      >The vehicle will be transported to this impound</Label
    >
  </div>

  <div class="field">
    <Label label-for="description">Description</Label>
    <TextInput
      id="description"
      name="description"
      :multiline="true"
      :maxLength="300"
      v-model="store.storeVehicle!.reasonForImpound"
    />
    <Label class="summarise"
      >Describe the reason for impounding the vehicle</Label
    >
  </div>

  <div class="field">
    <Label label-for="impoundFor">Impound for</Label>
    <SingleSelect
      id="impoundFor"
      name="impoundFor"
      :options="timePeriods"
      v-model="store.storeVehicle!.expiryHours"
    />
    <Label class="summarise"
      >People will not be able to retrieve the vehicle until the Date/Time
      selected</Label
    >
  </div>

  <div class="field">
    <div class="toggle-row">
      <ToggleSwitch
        id="allowPersonal"
        name="allowPersonal"
        v-model="store.storeVehicle!.allowPersonalUnimpound"
      />
      <Label label-for="allowPersonal">Allow personal un-impound</Label>
    </div>
    <Label class="summarise"
      >This will allow citizens to retrieve their vehicle by paying a fee once
      the impound timer expires</Label
    >
  </div>
</template>

<style scoped>
.field {
  margin-bottom: 2rem;
}

.summarise {
  margin-top: 0.3rem;
}

.toggle-row {
  display: flex;
  align-items: center; /* vertically center them */
  gap: 0.5rem; /* space between toggle and text */
}

.fixed-height-select {
  height: 2.5rem;
  max-height: 2.5rem;
  line-height: 2.5rem;
}
</style>
