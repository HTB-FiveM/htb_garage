// Import necessary utilities from Vue Test Utils and other libraries as needed
import { config } from '@vue/test-utils'

// Mock global properties and methods
globalThis.fetch = vi.fn(() =>
  Promise.resolve(new Response(JSON.stringify({ json: () => Promise.resolve({}) })))
)

// Configure Vue Test Utils
config.global.mocks = {
  // Mock Vue Router, Vuex store, or other global properties here
  // $route: { ... },
  // $store: { ... },
}

// Example of installing a global Vue plugin, if necessary
// import someGlobalPlugin from 'some-global-plugin';
// config.global.plugins.push([someGlobalPlugin]);

// Set up any other global configurations or mocks
