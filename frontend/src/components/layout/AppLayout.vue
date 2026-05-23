<template>
  <div style="display:flex; min-height:100vh;">
    <Sidebar />
    <div style="flex:1; margin-left:240px; display:flex; flex-direction:column;">
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
