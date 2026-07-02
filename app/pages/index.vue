<script setup lang="ts">
const config = useRuntimeConfig()
const supabaseConfigured = isSupabaseConfigured(
  config.public.supabaseUrl,
  config.public.supabaseKey,
)
</script>

<template>
  <v-container class="fill-height">
    <v-row justify="center" align="center">
      <v-col cols="12" sm="8" md="6">
        <v-card class="text-center pa-4">
          <v-card-title class="text-h4">Chore Corral</v-card-title>
          <v-card-subtitle>Farm task tracking</v-card-subtitle>
          <v-card-text>
            <p class="mb-4">M1 — Scaffold &amp; Deploy</p>
            <v-chip
              :color="supabaseConfigured ? 'success' : 'warning'"
              variant="tonal"
            >
              Supabase
              {{ supabaseConfigured ? 'configured' : 'not configured' }}
            </v-chip>
          </v-card-text>
          <v-card-actions class="justify-center">
            <v-btn color="primary" variant="tonal" to="/components-demo">
              Vuetify components demo
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>
