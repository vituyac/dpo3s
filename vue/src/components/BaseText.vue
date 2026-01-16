<script setup>
const props = defineProps({
  label: String,
  modelValue: {
    type: String,
    default: "",
  },
  placeholder: String,
});

const emit = defineEmits(["update:modelValue"]);

const updateValue = (event) => {
  emit("update:modelValue", event.target.value);
};
</script>

<template>
  <div>
    <label class="block text-sm font-medium mb-1">{{ label }}</label>
    <textarea
      :value="modelValue"
      @input="updateValue"
      class="w-full border rounded px-3 py-2 focus:outline-none focus:ring focus:border-blue-500"
      :placeholder="placeholder"
    ></textarea>
  </div>
</template>

<style scoped></style>
