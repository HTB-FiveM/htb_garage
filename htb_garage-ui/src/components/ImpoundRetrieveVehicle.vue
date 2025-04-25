<script lang="ts" setup>
import { useImpoundStore } from '@/stores/impound.store';
import type { ImpoundVehicle } from '@/types/impoundTypes';
import { computed, inject, ref } from 'vue';

import ImpoundVehiceItem from "@/components/ImpoundVehicleItem.vue";
import TextInput from '@/components/TextInput.vue';
import Button from "@/components/Button.vue";
import Alert from "@/components/Alert.vue";

const store = useImpoundStore();

const searchTerm = ref('');
const filteredVehicles = computed<ImpoundVehicle[] | undefined >(() => {
  return store.filteredVehicles(searchTerm.value);
});

const closeApp = inject<() => void>('closeApp')!;
function onCloseClick() {
  closeApp()
}
const spawnVehicle = async (vehicle: ImpoundVehicle) => {
  await store.takeOut(vehicle, false);
  onCloseClick();
};
</script>

<template>
    <div>
        <TextInput
            type="text"
            ref="searchBox"
            class="form-control"
            placeholder="Search the vehicles by plate or name"
            v-model="searchTerm"
        />
    </div>
    <div class="car-list">
        <Alert
            v-if="store.retrieveVehicle!.vehicles.length > 0 && filteredVehicles?.length === 0"
            variant="warning"
            style="display:flex; margin: .5rem;"
        >No vehicles matching criteria</Alert>
        <ul v-else>
            <li v-for="vehicle in filteredVehicles" class="impound-list-item">
                <ImpoundVehiceItem :veh="vehicle">
                    <div class="details-panel">
                        <div class="action-buttons">

                            <!-- <a
                            v-if="veh.pound"
                            type="button"
                            class="btn btn-dark btn-sm disabled"
                            >Impounded
                            </a>
                            <div v-else>
                            <button
                                v-if="veh.stored"
                                type="button"
                                class="btn btn-success btn-sm"
                                @click="takeOutVehicle(veh)"
                            >
                                Take out
                            </button>

                            </div> -->
                            <div class="item-buttons">
                                <Button @click="spawnVehicle(vehicle)">Spawn vehicle</Button>
                                <Button variant="secondary" @click="">Return to owner</Button>
                            </div>
                        </div>
                    </div>
                </ImpoundVehiceItem>
            </li>
        </ul>
    </div>
</template>

<style scoped>
ul {
    padding: .5rem .3rem 0 .3rem;
}


.impound-list-item {
    list-style-type: none;
    position: relative;
    display: block;
    padding: .2rem .2rem .2rem .2rem;
    margin-bottom: 1rem;
    /* border: 1px solid rgba(0, 0, 0, 0.125); */
    border-bottom: 1px sold rgba(0, 0, 0, 0.125);

}

.car-list {
    margin-top: .5rem;
    border-radius: 5px;
    /* border-style: solid;
    border-color: #a0a0a0; */
}

.impound-list-item {
  /* box-shadow: horizontal-offset vertical-offset blur-radius spread-radius color */
  box-shadow: 0 0 5px 2px rgba(0, 0, 0, 0.1);

  border-radius: 4px;
  padding: 1rem;
}

.item-buttons {
    display: flex;            /* turn on flex layout */
    justify-content: center;  /* center along the main axis (horizontally) */
    align-items: center;      /* center along the cross axis (vertically) */
    gap: 1rem;                /* optional spacing between buttons */
    /* if you want the wrapper to fill some height: */

}

</style>
