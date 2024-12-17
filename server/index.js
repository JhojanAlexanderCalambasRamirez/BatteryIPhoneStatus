const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const bodyParser = require('body-parser');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(bodyParser.json());

let batteryData = { battery: null, timestamp: null }; // Datos iniciales predeterminados

// Ruta para recibir datos del iPhone
app.post('/update-battery', (req, res) => {
  console.log('Data received:', req.body);
  const { battery, timestamp } = req.body;

  if (
    typeof battery === 'number' &&
    battery >= 0 &&
    battery <= 100 &&
    typeof timestamp === 'string' &&
    Date.parse(timestamp)
  ) {
    batteryData = { battery, timestamp };
    io.emit('batteryUpdate', batteryData); // Enviar datos a los clientes conectados
    console.log(`Battery update received: ${battery}% at ${timestamp}`);
    res.send('Battery status received');
  } else {
    console.error('Invalid data received:', req.body);
    res.status(400).send('Invalid data format');
  }
});

// Socket.IO para manejar conexiones en tiempo real
io.on('connection', (socket) => {
  console.log('Client connected');
  // Enviar los datos actuales al cliente cuando se conecte
  socket.emit('batteryUpdate', batteryData);
});

// Servidor escuchando en el puerto 3000
server.listen(3000, () => {
  console.log('Server running on http://192.168.1.11:3000');
});
