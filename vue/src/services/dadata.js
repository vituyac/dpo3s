import axios from "axios";

const token = import.meta.env.VITE_DADATA_TOKEN;

const client = axios.create({
  baseURL: "https://suggestions.dadata.ru/suggestions/api/4_1/rs",
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
    Authorization: "Token " + token,
  },
});

export async function suggestCities(query) {
  if (!query || query.length < 2) return [];

  const { data } = await client.post("/suggest/address", {
    query,
    from_bound: { value: "city" },
    to_bound: { value: "city" },
    restrict_value: true,
  });

  return data.suggestions.map((item) => ({
    label: item.data.city,
  }));
}

export async function suggestUniversities(query) {
  if (!query || query.length <= 1) return [];

  const { data } = await client.post("/suggest/party", {
    query,
    okved: ["85.22"],
  });

  return data.suggestions.map((item) => ({
    label: item.data.name?.short_with_opf,
  }));
}
