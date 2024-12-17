const { app, BrowserWindow } = require('electron');
const io = require('socket.io-client');

let mainWindow;

app.on('ready', () => {
    mainWindow = new BrowserWindow({
        width: 400,
        height: 300,
        webPreferences: {
            nodeIntegration: true,
        },
    });

    mainWindow.loadURL('data:text/html;charset=utf-8,' + encodeURIComponent(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Battery Status</title>
            <style>
                body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
                h1 { font-size: 24px; color: #333; }
                #battery { font-size: 18px; color: #555; }
            </style>
        </head>
        <body>
            <h1>Battery Status</h1>
            <div id="battery">Waiting for updates...</div>
            <script>
                const { ipcRenderer } = require('electron');
                ipcRenderer.on('battery-update', (event, data) => {
                    document.getElementById('battery').innerText = \`Battery: \${data.battery}% at \${new Date(data.timestamp).toLocaleString()}\`;
                });
            </script>
        </body>
        </html>
    `));

    const socket = io('http://192.168.1.11:3000');
    socket.on('battery-update', (data) => {
        mainWindow.webContents.send('battery-update', data);
    });
});
