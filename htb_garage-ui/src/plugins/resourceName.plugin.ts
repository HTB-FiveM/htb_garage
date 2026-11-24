// This plugin will provide a globally available variable called $resourceName in every store created in this project
import type { PiniaPluginContext } from 'pinia';

export const resourcePlugin = ({ store }: PiniaPluginContext) => {
  store.$resourceName = typeof window.GetParentResourceName === 'function' ? window.GetParentResourceName() : 'dev';
};

declare module 'pinia' {
  export interface PiniaCustomProperties {
    $resourceName: string;
  }
}
// Now every store (and any component via useStore()) can access store.$resourceName.
