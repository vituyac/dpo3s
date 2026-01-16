<script setup>
import { ref, watch } from "vue";
import { suggestUniversities } from "@/services/dadata";
import BaseInput from "./BaseInput.vue";
import BaseButton from "./BaseButton.vue";

const props = defineProps({
  education: Object,
});

const emit = defineEmits(["updateEducation"]);

const university = ref("");
const eduFaculty = ref("");
const eduSpecialization = ref("");
const eduGradYear = ref("");

watch(
  () => props.education,
  (val) => {
    university.value = val.institution || "";
    eduFaculty.value = val.faculty || "";
    eduSpecialization.value = val.specialization || "";
    eduGradYear.value = val.gradYear || "";
  },
  { immediate: true, deep: true }
);

const apply = () => {
  emit("updateEducation", {
    level: props.education.level,
    institution: university.value,
    faculty: eduFaculty.value,
    specialization: eduSpecialization.value,
    gradYear: eduGradYear.value,
  });
};

const universitySuggestions = ref([]);
let debounceId = null;

const fetchUniversities = async () => {
  universitySuggestions.value = await suggestUniversities(university.value);
};

watch(university, () => {
  clearTimeout(debounceId);
  debounceId = setTimeout(fetchUniversities, 300);
});
</script>

<template>
  <div
    v-if="education.level !== 'secondary'"
    class="mt-2 flex flex-col gap-4 bg-white rounded-xl border-2 border-gray-500 p-4"
  >
    <div class="flex gap-4">
      <BaseInput
        v-model="university"
        label="Учебное заведение"
        placeholder="Введите учебное заведение"
        :suggestions="universitySuggestions"
      />
      <BaseInput
        v-model="eduFaculty"
        label="Факультет"
        placeholder="Введите факультет"
      />
    </div>
    <BaseInput
      v-model="eduSpecialization"
      label="Специализация"
      placeholder="Введите специализацию"
    />
    <div class="flex gap-4">
      <BaseInput
        type="number"
        v-model="eduGradYear"
        label="Год окончания"
        placeholder="2026"
      />
      <div class="flex justify-end">
        <BaseButton label="Применить" @click="apply" />
      </div>
    </div>
  </div>
</template>

<style scoped></style>
