<script lang="ts" setup>
interface Props {
    modelValue: boolean;
    disabled?: boolean;
    id?: string;
    name?: string;
}

defineProps<Props>();
const emit = defineEmits<{
    (e: 'update:modelValue', value: boolean): void;
}>();

function onToggle(e: Event) {
    const checked = (e.target as HTMLInputElement).checked;
    emit('update:modelValue', checked);
}
</script>

<template>
    <label class="toggle-switch" :for="id">
        <input
            type="checkbox"
            :id="id"
            :name="name"
            :checked="modelValue"
            :disabled="disabled"
            @change="onToggle"
        />
        <span class="slider"></span>
    </label>
</template>

<style scoped>
.toggle-switch {
    display: inline-block;
    position: relative;
    width: 3rem;
    height: 1.5rem;
}
.toggle-switch input {
    opacity: 0;
    width: 0;
    height: 0;
}
.slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: #ccc;
    transition: background-color 0.3s ease;
    border-radius: 1.5rem;
}
.slider:before {
    position: absolute;
    content: "";
    height: 1.2rem;
    width: 1.2rem;
    left: 0.15rem;
    bottom: 0.15rem;
    background-color: #fff;
    transition: transform 0.3s ease;
    border-radius: 50%;
}

/* Checked state */
input:checked + .slider {
    background-color: rgba(30, 72, 86, 0.9);
}
input:checked + .slider:before {
    transform: translateX(1.5rem);
}

/* Focus glow */
input:focus + .slider {
    box-shadow:
        0 0 0 2px rgba(30, 72, 86, 0.9),
        0 0 8px 4px rgba(30, 72, 86, 0.3);
}

/* Disabled state */
input:disabled + .slider {
    background-color: #e6e6e6;
    cursor: not-allowed;
}
</style>
