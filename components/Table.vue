<template>
  <div class="px-4 sm:px-6 lg:px-8">
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-xl font-semibold text-gray-900">{{ title }}</h1>
        <p class="mt-2 text-sm text-gray-700">{{ description }}</p>
      </div>
    </div>
    <div class="mt-8">
      <slot name="filters"></slot>
    </div>
    <div v-if="hasData" class="mt-8 flex flex-col">
      <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle md:px-6 lg:px-8">
          <div
            class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 md:rounded-lg"
          >
            <table class="min-w-full divide-y divide-gray-300">
              <thead class="bg-gray-50">
                <tr>
                  <slot name="header"></slot>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 bg-white">
                <slot name="body"></slot>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    <div class="flex justify-center items-center py-12" v-else>
      <span v-if="isLoading"> Loading... </span>
      <span v-else> No data available </span>
    </div>
  </div>
</template>

<script lang="ts">
export default {
  name: 'Table',
  props: {
    title: String,
    description: String,
    hasData: Boolean,
    isLoading: Boolean,
  },
}
</script>
