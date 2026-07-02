<script setup lang="ts">
useHead({ title: 'Vuetify Components Demo — Chore Corral' })

const animals = ['Chickens', 'Goats', 'Horses', 'Pigs', 'Barn cats']
const assignees = ['Casey', 'Jordan', 'Riley', 'Sam']

const chores = [
  { chore: 'Feed the chickens', area: 'Coop', assignee: 'Casey', done: true },
  { chore: 'Muck the stalls', area: 'Barn', assignee: 'Jordan', done: false },
  { chore: 'Fix pasture fence', area: 'Field', assignee: 'Riley', done: false },
  { chore: 'Refill water troughs', area: 'Barn', assignee: 'Sam', done: true },
  { chore: 'Collect eggs', area: 'Coop', assignee: 'Casey', done: true },
]

const timelineEvents = [
  { time: '6:00 AM', text: 'Morning feed', color: 'success' },
  { time: '9:30 AM', text: 'Vet visit — goats', color: 'info' },
  { time: '2:00 PM', text: 'Hay delivery', color: 'warning' },
  { time: '6:30 PM', text: 'Evening feed & lockup', color: 'success' },
]

const choreName = ref('')
const choreNotes = ref('')
const selectedAnimal = ref<string | null>(null)
const selectedAssignees = ref<string[]>([])
const urgency = ref(3)
const feedRange = ref([2, 8])
const rating = ref(4)
const notifications = ref(true)
const autoAssign = ref(false)
const weatherOk = ref(true)
const frequency = ref('daily')
const tab = ref('barn')
const page = ref(1)
const stepperStep = ref(1)
const dialogOpen = ref(false)
const snackbarOpen = ref(false)
const btnToggle = ref('list')

const breadcrumbs = [
  { title: 'Home', to: '/' },
  { title: 'Demo', disabled: true },
  { title: 'Components', disabled: true },
]
</script>

<template>
  <v-container class="py-8">
    <v-breadcrumbs :items="breadcrumbs" class="px-0" />

    <h1 class="text-h3 mb-2">Vuetify Components Demo</h1>
    <p class="text-medium-emphasis mb-8">
      A sampler of Vuetify components with farm-flavored sample data.
    </p>

    <!-- Buttons -->
    <h2 class="text-h5 mb-4">Buttons</h2>
    <v-card class="pa-4 mb-8">
      <div class="d-flex flex-wrap ga-2 align-center mb-4">
        <v-btn color="primary">Elevated</v-btn>
        <v-btn color="secondary" variant="tonal">Tonal</v-btn>
        <v-btn color="success" variant="outlined">Outlined</v-btn>
        <v-btn color="warning" variant="text">Text</v-btn>
        <v-btn color="error" variant="plain">Plain</v-btn>
        <v-btn icon="mdi-tractor" color="primary" />
      </div>
      <v-btn-toggle v-model="btnToggle" color="primary" mandatory>
        <v-btn value="list" prepend-icon="mdi-format-list-bulleted">List</v-btn>
        <v-btn value="board" prepend-icon="mdi-view-column">Board</v-btn>
        <v-btn value="calendar" prepend-icon="mdi-calendar">Calendar</v-btn>
      </v-btn-toggle>
    </v-card>

    <!-- Form inputs -->
    <h2 class="text-h5 mb-4">Form inputs</h2>
    <v-card class="pa-4 mb-8">
      <v-row>
        <v-col cols="12" md="6">
          <v-text-field
            v-model="choreName"
            label="Chore name"
            placeholder="e.g. Muck the stalls"
            prepend-inner-icon="mdi-shovel"
          />
          <v-select
            v-model="selectedAnimal"
            :items="animals"
            label="Animal group"
            prepend-inner-icon="mdi-cow"
          />
          <v-autocomplete
            v-model="selectedAssignees"
            :items="assignees"
            label="Assignees"
            multiple
            chips
            closable-chips
            prepend-inner-icon="mdi-account-multiple"
          />
        </v-col>
        <v-col cols="12" md="6">
          <v-textarea
            v-model="choreNotes"
            label="Notes"
            placeholder="Watch out for the rooster."
            rows="3"
          />
          <v-file-input label="Attach a photo of the barn" />
          <v-combobox
            :items="['hay', 'feed', 'fencing', 'water', 'vet']"
            label="Tags (combobox — type your own)"
            multiple
            chips
          />
        </v-col>
      </v-row>
    </v-card>

    <!-- Selection controls -->
    <h2 class="text-h5 mb-4">Selection controls</h2>
    <v-card class="pa-4 mb-8">
      <v-row>
        <v-col cols="12" md="6">
          <v-checkbox v-model="weatherOk" label="Only if weather permits" />
          <v-switch
            v-model="notifications"
            color="primary"
            label="Notify me when overdue"
          />
          <v-switch
            v-model="autoAssign"
            color="primary"
            label="Auto-assign to whoever is closest to the barn"
          />
          <v-radio-group v-model="frequency" label="Frequency" inline>
            <v-radio label="Daily" value="daily" />
            <v-radio label="Weekly" value="weekly" />
            <v-radio label="When it smells" value="asneeded" />
          </v-radio-group>
        </v-col>
        <v-col cols="12" md="6">
          <v-slider
            v-model="urgency"
            label="Urgency"
            :min="1"
            :max="5"
            :step="1"
            show-ticks="always"
            thumb-label
          />
          <v-range-slider
            v-model="feedRange"
            label="Feed window (hours)"
            :min="0"
            :max="12"
            :step="1"
            thumb-label
          />
          <div class="d-flex align-center ga-4">
            <span>Barn cleanliness:</span>
            <v-rating v-model="rating" color="warning" hover />
          </div>
        </v-col>
      </v-row>
    </v-card>

    <!-- Chips, avatars & badges -->
    <h2 class="text-h5 mb-4">Chips, avatars &amp; badges</h2>
    <v-card class="pa-4 mb-8">
      <div class="d-flex flex-wrap ga-2 align-center mb-4">
        <v-chip color="success" variant="tonal">Done</v-chip>
        <v-chip color="warning" variant="tonal">Overdue</v-chip>
        <v-chip color="info" variant="outlined" prepend-icon="mdi-horse">
          Horses
        </v-chip>
        <v-chip color="error" closable>Escaped goat</v-chip>
      </div>
      <div class="d-flex flex-wrap ga-6 align-center">
        <v-avatar color="primary" size="48">CC</v-avatar>
        <v-avatar color="secondary" size="48">
          <v-icon icon="mdi-cow" />
        </v-avatar>
        <v-badge content="3" color="error">
          <v-icon icon="mdi-bell" size="32" />
        </v-badge>
        <v-badge dot color="success">
          <v-avatar color="surface-variant" size="40">JD</v-avatar>
        </v-badge>
      </div>
    </v-card>

    <!-- Alerts & progress -->
    <h2 class="text-h5 mb-4">Alerts &amp; progress</h2>
    <v-card class="pa-4 mb-8">
      <v-alert type="success" variant="tonal" class="mb-3">
        All morning chores complete. The chickens are pleased.
      </v-alert>
      <v-alert type="warning" variant="tonal" class="mb-3">
        Water trough in the north pasture is running low.
      </v-alert>
      <v-alert type="error" variant="tonal" class="mb-6" closable>
        Fence breach in sector 7 — goats at large.
      </v-alert>
      <v-progress-linear
        model-value="65"
        color="primary"
        height="10"
        rounded
        class="mb-6"
      />
      <div class="d-flex ga-6 align-center">
        <v-progress-circular model-value="65" color="primary" size="56">
          65%
        </v-progress-circular>
        <v-progress-circular indeterminate color="secondary" />
        <v-skeleton-loader type="list-item-avatar" width="280" />
      </div>
    </v-card>

    <!-- Data table & list -->
    <h2 class="text-h5 mb-4">Data table &amp; list</h2>
    <v-row class="mb-8">
      <v-col cols="12" md="7">
        <v-card>
          <v-data-table :items="chores" items-per-page="5">
            <template #[`item.done`]="{ value }">
              <v-icon
                :icon="value ? 'mdi-check-circle' : 'mdi-circle-outline'"
                :color="value ? 'success' : 'grey'"
              />
            </template>
          </v-data-table>
        </v-card>
      </v-col>
      <v-col cols="12" md="5">
        <v-card>
          <v-list lines="two">
            <v-list-subheader>Today's crew</v-list-subheader>
            <v-list-item
              v-for="name in assignees"
              :key="name"
              :title="name"
              subtitle="On chore duty"
            >
              <template #prepend>
                <v-avatar color="primary">{{ name[0] }}</v-avatar>
              </template>
              <template #append>
                <v-icon icon="mdi-chevron-right" />
              </template>
            </v-list-item>
          </v-list>
        </v-card>
      </v-col>
    </v-row>

    <!-- Tabs & expansion panels -->
    <h2 class="text-h5 mb-4">Tabs &amp; expansion panels</h2>
    <v-card class="mb-8">
      <v-tabs v-model="tab" color="primary">
        <v-tab value="barn">Barn</v-tab>
        <v-tab value="coop">Coop</v-tab>
        <v-tab value="field">Field</v-tab>
      </v-tabs>
      <v-window v-model="tab">
        <v-window-item value="barn">
          <v-card-text>Stalls, hay loft, and the tack room.</v-card-text>
        </v-window-item>
        <v-window-item value="coop">
          <v-card-text>Nesting boxes, roosts, and the run.</v-card-text>
        </v-window-item>
        <v-window-item value="field">
          <v-card-text>Pastures, fences, and the pond.</v-card-text>
        </v-window-item>
      </v-window>
    </v-card>
    <v-expansion-panels class="mb-8">
      <v-expansion-panel
        title="Why do the goats keep escaping?"
        text="Goats view fences as suggestions. Check post tension weekly."
      />
      <v-expansion-panel
        title="How often should troughs be scrubbed?"
        text="Weekly in summer, biweekly in winter, or whenever the algae wins."
      />
      <v-expansion-panel
        title="Who is on rooster duty?"
        text="Whoever lost the coin toss. Rotate for fairness."
      />
    </v-expansion-panels>

    <!-- Timeline & stepper -->
    <h2 class="text-h5 mb-4">Timeline &amp; stepper</h2>
    <v-row class="mb-8">
      <v-col cols="12" md="6">
        <v-card class="pa-4">
          <v-timeline density="compact" side="end">
            <v-timeline-item
              v-for="event in timelineEvents"
              :key="event.time"
              :dot-color="event.color"
              size="small"
            >
              <strong>{{ event.time }}</strong> — {{ event.text }}
            </v-timeline-item>
          </v-timeline>
        </v-card>
      </v-col>
      <v-col cols="12" md="6">
        <v-card>
          <v-stepper
            v-model="stepperStep"
            :items="['Pick chore', 'Assign', 'Done']"
          >
            <template #[`item.1`]>
              <v-card-text>Choose a chore from the corral.</v-card-text>
            </template>
            <template #[`item.2`]>
              <v-card-text>Wrangle a volunteer.</v-card-text>
            </template>
            <template #[`item.3`]>
              <v-card-text>Mark it done and take a bow.</v-card-text>
            </template>
          </v-stepper>
        </v-card>
      </v-col>
    </v-row>

    <!-- Overlays -->
    <h2 class="text-h5 mb-4">Dialogs, menus, tooltips &amp; snackbars</h2>
    <v-card class="pa-4 mb-8">
      <div class="d-flex flex-wrap ga-2 align-center">
        <v-btn color="primary" @click="dialogOpen = true">Open dialog</v-btn>
        <v-menu>
          <template #activator="{ props }">
            <v-btn v-bind="props" variant="tonal" append-icon="mdi-menu-down">
              Open menu
            </v-btn>
          </template>
          <v-list>
            <v-list-item
              v-for="animal in animals"
              :key="animal"
              :title="animal"
            />
          </v-list>
        </v-menu>
        <v-tooltip text="This button does nothing, but confidently.">
          <template #activator="{ props }">
            <v-btn v-bind="props" variant="outlined">Hover me</v-btn>
          </template>
        </v-tooltip>
        <v-btn variant="text" @click="snackbarOpen = true">
          Show snackbar
        </v-btn>
      </div>
      <v-dialog v-model="dialogOpen" max-width="400">
        <v-card
          title="Release the chickens?"
          text="They will return at dusk. Probably."
        >
          <v-card-actions>
            <v-spacer />
            <v-btn @click="dialogOpen = false">Cancel</v-btn>
            <v-btn color="primary" @click="dialogOpen = false">Release</v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
      <v-snackbar v-model="snackbarOpen" timeout="3000" color="success">
        Chore saved. The barn thanks you.
      </v-snackbar>
    </v-card>

    <!-- Pagination -->
    <h2 class="text-h5 mb-4">Pagination</h2>
    <v-card class="pa-4 mb-8 d-flex justify-center">
      <v-pagination v-model="page" :length="6" />
    </v-card>

    <v-btn to="/" variant="text" prepend-icon="mdi-arrow-left">
      Back to home
    </v-btn>
  </v-container>
</template>
