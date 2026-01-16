<script setup>
import { ref, onMounted, computed } from "vue";
import axios from "axios";
import draggable from "vuedraggable";
import BaseButton from "../components/BaseButton.vue";

const statuses = ref([
  { label: "Новый", value: "new" },
  { label: "Назначено собеседование", value: "interview" },
  { label: "Принят", value: "approved" },
  { label: "Отказ", value: "rejected" },
]);

const columns = ref({
  new: [],
  interview: [],
  approved: [],
  rejected: [],
});

onMounted(async () => {
  try {
    const { data } = await axios.get("http://localhost:8000/api/cv");

    const grouped = {
      new: [],
      interview: [],
      approved: [],
      rejected: [],
    };

    data.forEach((item) => {
      if (!grouped[item.status]) {
        grouped[item.status] = [];
      }
      grouped[item.status].push(item);
    });

    columns.value = grouped;
  } catch (error) {
    console.log(error);
  }
});

const calcAge = (birthDate) => {
  if (!birthDate) return "";

  const today = new Date();
  const d = new Date(birthDate);

  let age = today.getFullYear() - d.getFullYear();
  const m = today.getMonth() - d.getMonth();

  if (m < 0 || (m === 0 && today.getDate() < d.getDate())) {
    age--;
  }

  return age;
};

const updateStatus = async (id, status) => {
  try {
    await axios.patch(`http://localhost:8000/api/cv/${id}`, {
      status,
    });
  } catch (e) {
    console.error(e.response?.data || e);
  }
};

const onChange = async (newStatus, evt) => {
  if (evt.added) {
    const item = evt.added.element;
    item.status = newStatus;
    await updateStatus(item.id, newStatus);
  }
};

const maxCount = computed(() => {
  const lists = Object.values(columns.value || {});
  if (!lists.length) return 1;
  const counts = lists.map((l) => (l ? l.length : 0));
  const max = Math.max(...counts);
  return max || 1;
});
</script>

<template>
  <div class="flex flex-col mx-10">
    <RouterLink to="/cv/create">
      <BaseButton label="Создать" />
    </RouterLink>

    <div class="flex gap-4 mt-4">
      <div
        v-for="status in statuses"
        :key="status.value"
        class="flex-1 border rounded-lg min-h-max flex flex-col p-2"
      >
        <div class="text-center font-medium mb-2">
          {{ status.label }} ({{ columns[status.value]?.length || 0 }})
        </div>

        <draggable
          v-model="columns[status.value]"
          :group="'resumes'"
          item-key="id"
          class="flex flex-col gap-2 w-full h-max"
          :style="{ minHeight: `${maxCount * 90}px` }"
          @change="(evt) => onChange(status.value, evt)"
        >
          <template #item="{ element }">
            <RouterLink
              :to="`/cv/${element.id}`"
              class="border rounded-lg p-4 flex gap-4 items-center w-full cursor-pointer hover:scale-102 transition-transform duration-200 hover:shadow-md bg-white"
            >
              <img
                :src="element.photo_link"
                alt="Фото"
                class="w-16 h-16 rounded-full object-cover bg-gray-200"
              />

              <div class="flex flex-col">
                <div class="font-semibold text-lg leading-tight">
                  {{ element.fio }}
                </div>
                <div class="text-sm leading-tight">
                  {{ element.profession }}
                </div>
                <div class="text-xs text-gray-500">
                  {{ calcAge(element.birth_date) }} лет
                </div>
              </div>
            </RouterLink>
          </template>
        </draggable>
      </div>
    </div>
  </div>
</template>

<style scoped></style>
