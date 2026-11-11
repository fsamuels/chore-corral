<script setup lang="ts">
import { farmCenter } from '~/utils/active-farm'
import { formatSunTimeCompact } from '~/utils/sun-times'

// Today's sunrise/sunset, stacked small and muted beside the header's menu
// button (Home only, see default.vue) — space the mobile header leaves empty,
// so it costs no vertical room. Device location when access is granted,
// otherwise the active farm's default map centre; see useSunTimes.
const { activeFarm } = useFarms()
const { sunTimes, canUseDeviceLocation, locating, requestDeviceLocation } =
  useSunTimes(() => farmCenter(activeFarm.value))
</script>

<template>
  <component
    :is="canUseDeviceLocation ? 'button' : 'div'"
    v-if="sunTimes || canUseDeviceLocation"
    class="header-sun"
    data-testid="sun-times"
    v-bind="
      canUseDeviceLocation
        ? {
            type: 'button',
            disabled: locating,
            title: 'Use my location for sunrise and sunset',
          }
        : {}
    "
    @click="canUseDeviceLocation && requestDeviceLocation()"
  >
    <!-- Nothing to show until location is shared (no farm centre either):
         an icon-only button, so it doesn't crowd the farm name. -->
    <template v-if="!sunTimes">
      <v-icon icon="mdi-weather-sunset" size="22" />
      <span class="cc-sr-only">Show sunrise and sunset</span>
    </template>
    <template v-else-if="sunTimes.kind === 'normal'">
      <span class="header-sun__line">
        <v-icon icon="mdi-weather-sunset-up" size="13" />
        <span class="cc-sr-only">Sunrise</span>
        {{ formatSunTimeCompact(sunTimes.sunrise) }}
      </span>
      <span class="header-sun__line">
        <v-icon icon="mdi-weather-sunset-down" size="13" />
        <span class="cc-sr-only">Sunset</span>
        {{ formatSunTimeCompact(sunTimes.sunset) }}
      </span>
    </template>
    <span v-else class="header-sun__line">
      <v-icon
        :icon="
          sunTimes.kind === 'polar-day'
            ? 'mdi-white-balance-sunny'
            : 'mdi-weather-night'
        "
        size="13"
      />
      {{
        sunTimes.kind === 'polar-day' ? 'Sun up all day' : 'Sun down all day'
      }}
    </span>
    <v-icon
      v-if="canUseDeviceLocation"
      icon="mdi-crosshairs-gps"
      size="12"
      class="header-sun__gps"
      aria-hidden="true"
    />
  </component>
</template>

<style scoped>
.header-sun {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  font-size: 0.75rem;
  font-weight: 600;
  line-height: 1.2;
  color: var(--cc-ink-muted);
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
}

.header-sun__line {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

button.header-sun {
  background: none;
  border: 0;
  padding: 0;
  font-family: inherit;
  cursor: pointer;
}

button.header-sun:disabled {
  cursor: progress;
  opacity: 0.6;
}

.header-sun__gps {
  position: absolute;
  top: -10px;
  right: -2px;
}
</style>
