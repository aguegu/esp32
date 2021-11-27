<script setup>
import { ref, onMounted } from 'vue';
const hostname = ref('ESP32');
const led = ref(0);
const chipid = ref();
const uptime = ref(0);
const heap = ref();

const fetchLed = async () => {
  led.value = await fetch('api/led').then((res) => res.text()).then(Number);
}

const toggleLed = async () => {
  await fetch('api/led', { method: 'POST' });
  fetchLed();
};

const fetchNode = async () => {
  [hostname.value, chipid.value, uptime.value, heap.value] = await fetch('api/node').then((res) => res.text()).then(s => s.split(','));
};

const refresh = () => {
  fetchLed();
  fetchNode();
};

onMounted(() => {
  refresh();
});

</script>

<template>
  <div class="container mx-auto space-y-2 max-w-md p-2">
    <button type="button" @click="refresh" class="text-6xl font-bold">{{ hostname }}</button>
    <div>Chip ID: <span class="font-mono">{{ chipid }}</span></div>
    <div>Uptime: {{ uptime }} ({{ (uptime / 1000000).toFixed(0) }} seconds)</div>
    <div>Heap: {{ heap }}</div>
    <!-- <span v-if="led" style="color: Turquoise;">&FilledSmallSquare;</span>
    <span v-else>&EmptySmallSquare;</span> -->
    <button type="button" @click="toggleLed" class="rounded-lg px-5 py-2 border shadow border-blue-500" :class="{ 'bg-blue-500': led, 'text-white': led, 'text-blue-500': !led }">Toggle LED</button>

  </div>
</template>
