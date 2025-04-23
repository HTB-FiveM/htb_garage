<script lang="ts" setup>
import ImpoundStore from "@/components/ImpoundStoreVehicle.vue";
import ImpoundRetrieve from "@/components/ImpoundRetrieveVehicle.vue";
import Button from "@/components/Button.vue";
import { useImpoundStore } from "@/stores/impound.store";
import { inject } from "vue";

const store = useImpoundStore();

const closeApp = inject<() => void>('closeApp')!;
function onCloseClick() {
  closeApp()
}


const impoundVehicle = () => {
    store.impoundVehicle({
        ...store.storeVehicle!
    });
};

</script>

<template>
    <div class="menu-header">
        <div><strong>Impound a vehicle - {{ store.storeVehicle?.vehiclePlate }}</strong></div>
    </div>

    <div id="app-border">
        <div class="the-form">
            <ImpoundStore v-if="store.mode === 'store'" />
            <ImpoundRetrieve v-if="store.mode === 'retrieve'" />
        </div>
    </div>

    <div class="action-bar">
        <div class="buttons">
            <Button variant="primary" @click="impoundVehicle">Send to impound</Button>
            <Button variant="outline" @click="onCloseClick">Cancel</Button>
        </div>
    </div>
    <!-- <pre>{{ store.storeVehicle }}</pre> -->
</template>

<style>
#app {
    width: 50%;
}
</style>

<style scoped>
#app-border {
    background-color: darkgray;
    padding: 10px 10px 15px 15px;
    border-radius: 7px;
}

.menu-header {
    margin-bottom: 5px;
    background-color: rgb(132, 131, 131);
    color: ghostwhite;
}

.menu-header,
.top-row {
    margin-bottom: 10px;
}

.top-row {
    display: flex;
    flex-wrap: nowrap;
    justify-content: space-between;
}
  
.the-form {
    border-radius: 5px;
    margin-top: 1px;
    margin-bottom: 1px;
    color: ghostwhite;
}

</style>

<style>
.summarise {
    color: rgb(84, 84, 84);
}

.action-bar {
  display: flex;
  align-items: center;
  /* no justify-content here so items sit next to each other */
}

.buttons {
    margin-top: 1rem;
    margin-bottom: 1rem;
    margin-left: auto;  /* pushes this block to the right */
    display: flex;
    gap: 1rem;
}


</style>