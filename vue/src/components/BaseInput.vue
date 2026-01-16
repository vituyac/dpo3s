<script setup>
import { ref, watch } from "vue";

const props = defineProps({
  label: String,
  placeholder: String,
  type: {
    type: String,
    default: "text",
  },
  modelValue: {
    type: String,
    default: "",
  },
  error: {
    type: String,
    default: "",
  },
  phoneMask: {
    type: Boolean,
    default: false,
  },
  suggestions: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(["update:modelValue"]);

const onInput = (event) => {
  if (!props.phoneMask) {
    emit("update:modelValue", event.target.value);
    return;
  }

  let digits = event.target.value.replace(/\D/g, "");

  if (!digits) {
    event.target.value = "";
    emit("update:modelValue", "");
    return;
  }

  if (digits[0] === "7" || digits[0] === "8") {
    digits = "8" + digits.slice(1);
  } else {
    digits = "8" + digits;
  }

  if (digits.length > 11) {
    digits = digits.slice(0, 11);
  }

  event.target.value = digits;
  emit("update:modelValue", digits);
};

const showSuggestions = ref(false);

const selectSuggestion = (label) => {
  emit("update:modelValue", label);
  showSuggestions.value = false;
};

watch(
  () => props.suggestions,
  (val) => {
    if (
      props.suggestions.length == 1 &&
      props.modelValue.trim() == props.suggestions[0].label.trim()
    ) {
      showSuggestions.value = false;
      return;
    }
    showSuggestions.value = Array.isArray(val) && val.length > 0;
  }
);
</script>

<template>
  <div class="flex-1">
    <label
      class="block text-sm font-medium mb-1"
      :class="error ? 'text-red-500' : ''"
    >
      {{ label }}
    </label>

    <div class="relative">
      <input
        :type="type"
        :value="modelValue"
        @input="onInput"
        :placeholder="placeholder"
        class="w-full border rounded px-3 py-2 focus:outline-none"
        :class="
          error
            ? 'border-red-500 text-red-500'
            : 'focus:ring focus:border-blue-500'
        "
      />

      <ul
        v-if="showSuggestions && suggestions && suggestions.length"
        class="absolute top-full mt-2 left-0 w-full z-50 bg-white border rounded shadow max-h-60 overflow-auto"
      >
        <li
          v-for="item in suggestions"
          :key="item.label"
          class="px-3 py-2 hover:bg-gray-100 cursor-pointer"
          @click="selectSuggestion(item.label)"
        >
          {{ item.label }}
        </li>
      </ul>
    </div>

    <p v-if="error" class="text-xs text-red-500 mt-1">
      {{ error }}
    </p>
  </div>
</template>
