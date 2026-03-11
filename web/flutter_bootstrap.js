{{flutter_js}}
{{flutter_build_config}}

async function clearLegacyFlutterCaches() {
  if ('caches' in window) {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
  }

  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
}

window.addEventListener('load', async function () {
  try {
    await clearLegacyFlutterCaches();
  } catch (_) {
    // Do not block app startup when cache cleanup fails.
  }

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    }
  });
});
