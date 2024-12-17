const { app, BrowserWindow, ipcMain } = require('electron');
const io = require('socket.io-client');

let mainWindow;

// Crear la ventana principal de la aplicación
app.whenReady().then(() => {
  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  mainWindow.loadFile('index.html');

  // Conectar al servidor Socket.IO
  const socket = io('http://192.168.1.11:3000');

  socket.on('batteryUpdate', (data) => {
    console.log('Battery update received:', data);
    if (data && data.battery !== null && data.timestamp) {
      mainWindow.webContents.send('battery-update', data);
    }
  });
});

// Salir de la aplicación cuando todas las ventanas estén cerradas
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
