const { app, BrowserWindow, ipcMain } = require('electron');
const io = require('socket.io-client');
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const bodyParser = require('body-parser');

let mainWindow;
let server;

// Iniciar el servidor integrado
function startServer() {
  const appExpress = express();
  const httpServer = http.createServer(appExpress);
  const ioServer = socketIo(httpServer);

  appExpress.use(bodyParser.json());

  let batteryData = { battery: null, timestamp: null };

  // Ruta para recibir datos del iPhone
  appExpress.post('/update-battery', (req, res) => {
    console.log('Data received:', req.body);
    const { battery, timestamp, namecel } = req.body;

    if (
      typeof battery === 'number' &&
      battery >= 0 &&
      battery <= 100 &&
      typeof timestamp === 'string' &&
      Date.parse(timestamp)
    ) {
      batteryData = { battery, timestamp, namecel: namecel || 'iPhone' };
      ioServer.emit('batteryUpdate', batteryData);
      console.log(`Battery update received: ${battery}% from ${namecel || 'iPhone'} at ${timestamp}`);
      res.send('Battery status received');
    } else {
      console.error('Invalid data received:', req.body);
      res.status(400).send('Invalid data format');
    }
  });

  // Socket.IO para manejar conexiones
  ioServer.on('connection', (socket) => {
    console.log('Client connected');
    socket.emit('batteryUpdate', batteryData);
  });

  // Iniciar servidor en puerto 3000
  server = httpServer.listen(3000, () => {
    console.log('Server running on http://localhost:3000');
  });
}

// Crear la ventana principal de la aplicación
app.whenReady().then(() => {
  // Iniciar el servidor integrado
  startServer();

  mainWindow = new BrowserWindow({
    width: 500,
    height: 700,
    resizable: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  mainWindow.loadFile('index.html');

  // Conectar al servidor Socket.IO local
  const socket = io('http://localhost:3000');

  socket.on('batteryUpdate', (data) => {
    console.log('Battery update received:', data);
    if (data && data.battery !== null && data.timestamp) {
      mainWindow.webContents.send('battery-update', data);
    }
  });
});

// Salir de la aplicación cuando todas las ventanas estén cerradas
app.on('window-all-closed', () => {
  if (server) {
    server.close();
  }
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
