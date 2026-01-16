<script setup>
const props = defineProps({
  label: String,
  onClick: Function,
});
</script>

<template>
  <button
    type="button"
    class="px-4 py-2 mt-6 rounded bg-blue-500 text-white text-sm hover:bg-blue-600 cursor-pointer"
    @click="onClick"
  >
    {{ label }}
  </button>
</template>

<style scoped></style>