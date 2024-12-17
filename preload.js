const { contextBridge, ipcRenderer } = require('electron');

// Exponer solo las funciones necesarias al renderizador
contextBridge.exposeInMainWorld('api', {
  onBatteryUpdate: (callback) => ipcRenderer.on('battery-update', callback),
});
