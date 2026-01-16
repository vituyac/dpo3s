<script setup>
const props = defineProps({
  label: String,
  modelValue: {
    type: String,
    default: "",
  },
  options: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(["update:modelValue"]);

const onChange = (event) => {
  emit("update:modelValue", event.target.value);
};
</script>

<template>
  <div class="flex-1">
    <label class="block text-sm font-medium mb-1">
      {{ label }}
    </label>

    <div class="relative">
      <select
        :value="modelValue"
        @change="onChange"
        class="w-full h-11 border rounded pl-3 pr-12 text-sm bg-white appearance-none focus:outline-none focus:ring focus:border-blue-500"
      >
        <option v-for="opt in options" :key="opt.value" :value="opt.value">
          {{ opt.label }}
        </option>
      </select>

      <span
        class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3"
      >
        <svg
          class="h-5 w-5 text-gray-500"
          fill="none"
          viewBox="0 0 20 20"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M7 7l3 3 3-3"
          />
        </svg>
      </span>
    </div>
  </div>
</template>

<style scoped></style>
