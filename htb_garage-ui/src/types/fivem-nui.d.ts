export {};

declare global {
  /** Injected by FiveM’s NUI runtime inside CEF */
  interface Window {
    GetParentResourceName?: () => string;
  }

  /** If you ever call it directly without the `window.` prefix */
  function GetParentResourceName(): string;
}
