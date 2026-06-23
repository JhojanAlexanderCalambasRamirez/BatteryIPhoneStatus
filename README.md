<p align="center">
  <img src="Images/LogoBatteryApp.png" alt="BatteryIPhoneStatus Logo" width="200">
</p>

<h1 align="center">BatteryIPhoneStatus</h1>

<p align="center">
  <strong>Monitor de batería de iPhone en tiempo real desde macOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-blue?logo=swift" alt="SwiftUI">
  <img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/iOS-17%2B-black?logo=apple" alt="iOS">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

---

Aplicacion nativa Swift que muestra el nivel de carga de tu iPhone directamente en la barra de menu del Mac. Sin servidores externos, sin configuracion de IPs, sin atajos complicados. Solo dos apps que se descubren automaticamente en tu red local.

## Caracteristicas

- **Menu bar nativo** — El nivel de bateria de tu iPhone siempre visible en la barra de menu del Mac
- **Descubrimiento automatico** — Las apps se encuentran solas via Bonjour/mDNS. Sin configurar IPs ni puertos
- **Tiempo real** — Actualizaciones cada 60 segundos o cuando el nivel de bateria cambia
- **Notificaciones inteligentes** — Alertas nativas en Mac cuando la bateria baja al 20%, 10% o se carga al 100%
- **Estado de carga** — Muestra si el iPhone esta cargando, desconectado o completamente cargado
- **Iconos dinamicos** — El icono en menu bar cambia segun el nivel de bateria
- **Logo personalizado** — Icono de app propio en ambas plataformas
- **Creditos integrados** — Links a GitHub y LinkedIn dentro de las apps

## Arquitectura

El proyecto esta compuesto por tres modulos independientes que se comunican entre si:

```
┌─────────────────────┐         Bonjour + TCP          ┌─────────────────────┐
│   BatterySenderIOS  │ ─────────────────────────────>  │  BatteryMonitorMac  │
│     (iPhone app)    │    Network.framework (JSON)     │  (macOS menu bar)   │
└─────────────────────┘                                 └─────────────────────┘
         │                                                       │
         └──────────────┐                    ┌───────────────────┘
                        │                    │
                   ┌────┴────────────────────┴────┐
                   │        BatteryShared         │
                   │   (Swift Package — modelos   │
                   │    y constantes de red)       │
                   └──────────────────────────────┘
```

### BatteryShared (Swift Package)

Paquete compartido entre ambas apps. Contiene:

| Archivo | Descripcion |
|---------|-------------|
| `BatteryData.swift` | Modelo `Codable` con nivel, estado, nombre del dispositivo y timestamp |
| `NetworkConstants.swift` | Tipo de servicio Bonjour (`_batterymon._tcp`), parametros de red TCP |

### BatteryMonitorMac (macOS 14+)

App de barra de menu que recibe y muestra los datos de bateria del iPhone.

| Archivo | Descripcion |
|---------|-------------|
| `BatteryMonitorApp.swift` | Entry point, configura `MenuBarExtra` con icono dinamico |
| `BatteryReceiver.swift` | Servidor Bonjour + NWListener, recibe datos y gestiona notificaciones |
| `MenuBarView.swift` | UI del popover: gauge de bateria, estado, timestamp, creditos |

**Funcionalidades:**
- Vive exclusivamente en la menu bar (no aparece en el Dock)
- Publica servicio Bonjour `_batterymon._tcp` para que el iPhone lo descubra
- Recibe datos JSON via `NWConnection` (Network.framework)
- Muestra icono de bateria dinamico (0%, 25%, 50%, 75%, 100%)
- Envia notificaciones nativas:
  - Bateria baja (≤20%)
  - Bateria critica (≤10%) con sonido critico
  - Carga completa (100%)
- Reconnection automatica si se pierde la conexion
- Links a GitHub y LinkedIn en el menu

### BatterySenderIOS (iOS 17+)

App que lee la bateria del iPhone y la envia al Mac.

| Archivo | Descripcion |
|---------|-------------|
| `BatterySenderApp.swift` | Entry point, conecta `BatteryManager` con `NetworkSender` |
| `BatteryManager.swift` | Lee `UIDevice.batteryLevel` y observa cambios de nivel/estado |
| `NetworkSender.swift` | Busca Mac via `NWBrowser`, conecta y envia JSON por TCP |
| `ContentView.swift` | UI con circulo animado, icono de bateria, estado de conexion |

**Funcionalidades:**
- Lee bateria via `UIDevice.current.batteryLevel` y `batteryState`
- Monitorea cambios en tiempo real con `NotificationCenter`
- Timer de respaldo cada 60 segundos
- Descubre Mac automaticamente via Bonjour (`NWBrowser`)
- Envia datos como JSON sobre TCP (`NWConnection`)
- UI responsive con circulo de progreso animado
- Indicador de estado de conexion (buscando/conectando/conectado/desconectado)
- Icono de bateria que cambia segun nivel y estado de carga

## Stack tecnologico

| Componente | Tecnologia |
|------------|------------|
| Lenguaje | Swift 5.9 |
| UI Framework | SwiftUI |
| Networking | Network.framework (NWListener, NWBrowser, NWConnection) |
| Descubrimiento | Bonjour / mDNS |
| Notificaciones | UserNotifications (UNUserNotificationCenter) |
| Bateria iOS | UIDevice.batteryLevel + batteryState |
| Generacion de proyecto | XcodeGen |
| Codigo compartido | Swift Package Manager |

## Requisitos

| Requisito | Detalle |
|-----------|---------|
| Mac | Apple Silicon (M1 o superior) con macOS 14 Sonoma o posterior |
| iPhone | iPhone con iOS 17 o posterior |
| Red | Ambos dispositivos conectados a la misma red WiFi |
| Xcode | Version 15 o posterior (para compilar e instalar en iPhone) |
| Apple ID | Necesario para firmar la app iOS (cuenta gratuita funciona) |

## Instalacion

### 1. Clonar el repositorio

```bash
git clone https://github.com/JhojanAlexanderCalambasRamirez/BatteryIPhoneStatus.git
cd BatteryIPhoneStatus
```

### 2. Generar proyectos Xcode

```bash
# Instalar XcodeGen si no lo tienes
brew install xcodegen

# Generar proyecto macOS
cd BatteryMonitorMac && xcodegen generate && cd ..

# Generar proyecto iOS
cd BatterySenderIOS && xcodegen generate && cd ..
```

### 3. Abrir workspace

```bash
open BatteryMonitor.xcworkspace
```

### 4. Compilar e instalar app macOS

1. Seleccionar scheme **BatteryMonitorMac** con destino **My Mac**
2. Run (Cmd+R)
3. Aparece icono de bateria en la barra de menu
4. Si el firewall pregunta, permitir conexiones entrantes

**Para uso permanente:**
- Product > Archive > Distribute App > Copy App
- Mover `BatteryMonitorMac.app` a `/Applications`
- System Settings > General > Login Items > Agregar la app para inicio automatico

### 5. Compilar e instalar app iOS

1. Seleccionar scheme **BatterySenderIOS** con destino tu iPhone
2. En Signing & Capabilities, seleccionar tu Apple ID como Team
3. Run (Cmd+R)
4. En iPhone: Ajustes > General > VPN y administracion de dispositivos > Confiar en el perfil

**Nota sobre cuenta gratuita:** La app expira cada 7 dias con cuenta gratuita de Apple. Para renovar, conectar el iPhone al Mac y ejecutar Run desde Xcode nuevamente. Con Apple Developer Program ($99 USD/anio) la app no expira.

## Uso

1. **Abrir BatteryMonitorMac** en el Mac — aparece icono de bateria en la barra de menu
2. **Abrir Battery Sender** en el iPhone
3. El iPhone detecta el Mac automaticamente y comienza a enviar datos
4. Click en el icono de bateria en menu bar para ver detalles: nivel, estado, dispositivo y timestamp
5. Las notificaciones llegan automaticamente cuando la bateria baja o se completa la carga

## Estructura del proyecto

```
BatteryIPhoneStatus/
├── BatteryShared/                    # Swift Package compartido
│   ├── Package.swift
│   └── Sources/BatteryShared/
│       ├── BatteryData.swift         # Modelo de datos
│       └── NetworkConstants.swift    # Constantes Bonjour y red
├── BatteryMonitorMac/                # App macOS (menu bar)
│   ├── project.yml                   # Config XcodeGen
│   ├── Sources/
│   │   ├── BatteryMonitorApp.swift   # Entry point
│   │   ├── BatteryReceiver.swift     # Servidor Bonjour + receptor
│   │   └── MenuBarView.swift         # UI del menu
│   └── Resources/
│       ├── Info.plist
│       ├── BatteryMonitorMac.entitlements
│       └── Assets.xcassets/          # App icon
├── BatterySenderIOS/                 # App iOS (sender)
│   ├── project.yml                   # Config XcodeGen
│   ├── Sources/
│   │   ├── BatterySenderApp.swift    # Entry point
│   │   ├── BatteryManager.swift      # Monitor de bateria
│   │   ├── NetworkSender.swift       # Cliente Bonjour + sender
│   │   └── ContentView.swift         # UI principal
│   └── Resources/
│       ├── Info.plist
│       └── Assets.xcassets/          # App icon
├── BatteryMonitor.xcworkspace        # Workspace unificado
├── Images/
│   └── LogoBatteryApp.png            # Logo de la app
└── README.md
```

## Protocolo de comunicacion

Las apps se comunican usando un protocolo simple sobre TCP en la red local:

1. **Descubrimiento:** Mac publica servicio Bonjour `_batterymon._tcp`. iPhone lo busca con `NWBrowser`.
2. **Conexion:** iPhone establece conexion TCP via `NWConnection` al endpoint descubierto.
3. **Datos:** iPhone envia JSON codificado con `JSONEncoder` (ISO 8601 para fechas).

**Formato del mensaje:**

```json
{
  "level": 85,
  "state": "charging",
  "deviceName": "iPhone de Alexander",
  "timestamp": "2026-06-22T23:30:00Z"
}
```

**Estados posibles:** `unknown`, `unplugged`, `charging`, `full`

## Autor

<p align="center">
  <strong>Dev J4CR</strong> — Alexander Calambas
</p>

<p align="center">
  <a href="https://github.com/JhojanAlexanderCalambasRamirez">GitHub</a> •
  <a href="https://www.linkedin.com/in/j4cr/">LinkedIn</a>
</p>

## Licencia

Este proyecto esta bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para mas detalles.
