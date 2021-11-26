<script setup>
import { ref, onMounted } from 'vue';
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
  [chipid.value, uptime.value, heap.value] = await fetch('api/node').then((res) => res.text()).then(s => s.split(','));
};

// onMounted(() => {
//   fetchLed();
//   fetchNode();
// });

</script>

<template>
  <div class="container mx-auto space-y-4">
    <span class="block">Chip ID: {{ chipid }}</span>
    <span class="block">Uptime: {{ uptime }} ({{ (uptime / 1000000).toFixed(0) }} seconds)</span>
    <span class="block">Heap: {{ heap }}</span>
    <span v-if="led" style="color: Turquoise;">&FilledSmallSquare;</span>
    <span v-else>&EmptySmallSquare;</span>
    <button type="button" @click="toggleLed">Toggle LED</button>
    <button type="button" @click="fetchNode" class="rounded">Refresh</button>
  </div>
</template>
