import { createRouter, createWebHistory } from "vue-router";

import MainPage from "../pages/Main.vue";
import ResumeEditPage from "../pages/ResumeEdit.vue";
import ResumeCreatePage from "../pages/ResumeCreate.vue";

const routes = [
  { path: "/", component: MainPage },
  { path: "/cv/:id", component: ResumeEditPage },
  { path: "/cv/create", component: ResumeCreatePage },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

router.afterEach((to) => {
  const defaultTitle = "Vue";
  document.title = to.meta.title || defaultTitle;
});

export default router;
