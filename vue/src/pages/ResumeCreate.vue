<script setup>
import { ref, computed, watch } from "vue";
import { useRouter } from "vue-router";
import axios from "axios";
import { suggestCities } from "@/services/dadata";

import BaseInput from "../components/BaseInput.vue";
import BaseSelect from "../components/BaseSelect.vue";
import BaseText from "../components/BaseText.vue";
import EduForm from "../components/EduForm.vue";
import BaseButton from "../components/BaseButton.vue";

const router = useRouter();

const fio = ref("");
const email = ref("");
const phone = ref("");
const birthday = ref("");
const photo = ref("");
const salary = ref("");
const skills = ref("");
const profession = ref("");
const about = ref("");

const status = ref("new");
const statuses = ref([
  { label: "Новый", value: "new" },
  { label: "Назначено собеседование", value: "interview" },
  { label: "Принят", value: "approved" },
  { label: "Отказ", value: "rejected" },
]);

const education = ref({
  level: "secondary",
  institution: "",
  faculty: "",
  specialization: "",
  gradYear: "",
});

const educationChoices = ref([
  { label: "Среднее", value: "secondary" },
  { label: "Среднее специальное", value: "special" },
  { label: "Неоконченное высшее", value: "higher" },
  { label: "Высшее", value: "unhigher" },
]);

const city = ref("");
const citySuggestions = ref([]);

const errors = ref({
  fio: "",
  email: "",
  phone: "",
  birthday: "",
  city: "",
  profession: "",
  salary: "",
  status: "",
  educationLevel: "",
});

let debounceId = null;

const fetchCities = async () => {
  citySuggestions.value = await suggestCities(city.value);
};

watch(city, () => {
  clearTimeout(debounceId);
  debounceId = setTimeout(fetchCities, 300);
});

const isSaving = ref(false);

const validate = () => {
  const e = {
    fio: "",
    email: "",
    phone: "",
    birthday: "",
    city: "",
    profession: "",
    salary: "",
    status: "",
    educationLevel: "",
  };

  let valid = true;

  if (!fio.value.trim()) {
    e.fio = "Обязательное поле";
    valid = false;
  }
  if (!email.value.trim()) {
    e.email = "Обязательное поле";
    valid = false;
  }
  if (!phone.value.trim()) {
    e.phone = "Обязательное поле";
    valid = false;
  } else if (phone.value.length !== 11) {
    e.phone = "Номер должен содержать 11 цифр";
    valid = false;
  }
  if (!birthday.value) {
    e.birthday = "Обязательное поле";
    valid = false;
  }
  if (!city.value.trim()) {
    e.city = "Обязательное поле";
    valid = false;
  }
  if (!profession.value.trim()) {
    e.profession = "Обязательное поле";
    valid = false;
  }
  if (!salary.value.toString().trim()) {
    e.salary = "Обязательное поле";
    valid = false;
  }
  if (!status.value) {
    e.status = "Обязательное поле";
    valid = false;
  }
  if (!education.value.level) {
    e.educationLevel = "Обязательное поле";
    valid = false;
  }

  errors.value = e;
  return valid;
};

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const saveResume = async () => {
  if (!validate()) return;

  try {
    isSaving.value = true;

    await axios.post("http://localhost:8000/api/cv", {
      fio: fio.value,
      email: email.value,
      phone: phone.value,
      birth_date: birthday.value,
      photo_link: photo.value,
      salary: salary.value,
      skills: skills.value,
      profession: profession.value,
      about: about.value,
      status: status.value,
      city: city.value,
      level: education.value.level,
      institution: education.value.institution || null,
      faculty: education.value.faculty || null,
      specialization: education.value.specialization || null,
      grad_year: education.value.gradYear || null,
    });

    await delay(300);
    router.replace("/");
  } catch (e) {
    console.error(e.response?.data || e);
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="grid grid-cols-2 gap-8 p-8 h-screen">
    <div class="bg-white rounded-xl p-4 flex flex-col gap-4">
      <div class="flex gap-4">
        <BaseInput
          v-model="fio"
          label="ФИО"
          placeholder="Введите ФИО"
          :error="errors.fio"
        />
        <BaseInput
          v-model="email"
          type="email"
          label="Email"
          placeholder="Введите email"
          :error="errors.email"
        />
      </div>

      <div class="flex gap-4">
        <BaseInput
          v-model="city"
          :suggestions="citySuggestions"
          label="Город"
          placeholder="Введите город"
          :error="errors.city"
        />

        <BaseInput
          type="text"
          v-model="phone"
          label="Номер телефона"
          placeholder="Введите номер телефона"
          phoneMask
          :error="errors.phone"
        />
      </div>

      <div class="flex gap-4">
        <BaseInput
          v-model="birthday"
          type="date"
          label="Дата рождения"
          :error="errors.birthday"
        />
        <BaseSelect
          v-model="education.level"
          label="Уровень образования"
          :options="educationChoices"
          :error="errors.educationLevel"
        />
      </div>

      <EduForm :education="education" @updateEducation="education = $event" />

      <div class="flex gap-4">
        <BaseInput
          v-model="photo"
          label="Ссылка на фото"
          placeholder="Введите ссылку на фото"
        />
      </div>

      <div class="flex gap-4">
        <BaseInput
          v-model="profession"
          label="Профессия"
          placeholder="Введите профессию"
          :error="errors.profession"
        />
        <BaseInput
          v-model="salary"
          label="Желаемая зарплата"
          placeholder="Введите желаемую зарплату"
          :error="errors.salary"
        />
      </div>

      <BaseText
        v-model="skills"
        label="Ключевые навыки"
        placeholder="Введите ключевые навыки"
      />
      <BaseText
        v-model="about"
        label="О себе"
        placeholder="Введите информацию о себе"
      />

      <div class="flex gap-4 items-center">
        <BaseSelect
          v-model="status"
          label="Статус"
          :options="statuses"
          :error="errors.status"
        />
        <div class="flex justify-end">
          <BaseButton
            :label="isSaving ? 'Создаю…' : 'Создать'"
            :disabled="isSaving"
            @click="saveResume"
          />
        </div>
      </div>
    </div>

    <div class="bg-gray-200 rounded-xl p-4 flex flex-col gap-4">
      <div class="bg-white rounded-xl p-6 h-full flex flex-col gap-4">
        <div class="flex gap-4 items-center border-b pb-4">
          <div
            class="w-24 h-24 rounded-full bg-gray-300 overflow-hidden flex-shrink-0"
          >
            <img
              v-if="photo"
              :src="photo"
              alt="Фото"
              class="w-full h-full object-cover"
            />
          </div>

          <div>
            <div class="text-xl font-bold">{{ fio || "ФИО" }}</div>
            <div class="text-sm text-gray-600">
              {{ profession || "Профессия" }} • {{ city || "Город" }}
            </div>
            <div class="text-sm text-gray-600" v-if="birthday">
              Дата рождения: {{ birthday }}
            </div>
            <div class="text-sm text-gray-600" v-if="salary">
              Желаемая зарплата: {{ salary || "Не указана" }}
            </div>
          </div>
        </div>

        <div class="text-sm">
          <div class="font-semibold mb-1">Контакты</div>
          <div>Email: {{ email || "—" }}</div>
          <div>Телефон: {{ phone || "—" }}</div>
        </div>

        <div class="text-sm">
          <div class="font-semibold mb-1">Образование</div>
          <div v-if="education.level">
            {{
              educationChoices.find((item) => item.value === education.level)
                ?.label
            }}
          </div>
          <div v-if="education.level !== 'secondary'">
            <div v-if="education.institution">
              Учебное заведение: {{ education.institution }}
            </div>
            <div v-if="education.faculty">
              Факультет: {{ education.faculty }}
            </div>
            <div v-if="education.specialization">
              Специализация: {{ education.specialization }}
            </div>
            <div v-if="education.gradYear">
              Год окончания: {{ education.gradYear }}
            </div>
          </div>
        </div>

        <div class="text-sm">
          <div class="font-semibold mb-1">Ключевые навыки</div>
          <div class="whitespace-pre-line">{{ skills || "—" }}</div>
        </div>

        <div class="text-sm">
          <div class="font-semibold mb-1">О себе</div>
          <div class="whitespace-pre-line">{{ about || "—" }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped></style>
