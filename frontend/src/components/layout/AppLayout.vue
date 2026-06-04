<template>
  <div style="display:flex; min-height:100vh;">
    <Sidebar />
    <div class="flex-1 w-full flex flex-col" style="margin-left:240px;">
      <TopBar />
      <main class="main-content">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup>
import { RouterView } from 'vue-router'
import Sidebar from './Sidebar.vue'
import TopBar from './TopBar.vue'
</script>
