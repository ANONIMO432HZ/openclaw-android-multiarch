# 🚀 OpenClaw on Termux: Guía de Instalación Completa

Esta guía detalla el proceso para instalar y configurar el ecosistema de OpenClaw en dispositivos Android utilizando Termux, con soporte especializado para arquitecturas modernas (`aarch64`) y legadas (`armv7l`).

---

## 🏗️ 1. Arquitectura y Dualidad de Modo

El instalador detecta automáticamente el hardware y elige la mejor estrategia:

- **Modo glibc (aarch64)**: Utiliza un entorno Linux estándar sobre Android. Es el modo de mayor rendimiento para teléfonos modernos.
- **Modo Nativo (ARMv7/32-bit)**: Utiliza paquetes binarios de Termux directamente. Ideal para tablets antiguas y teléfonos de gama baja donde el entorno glibc no es compatible.

---

## 📦 2. Requisitos Previos

- **Termux**: Instale exclusivamente la versión de **F-Droid** o del repositorio oficial de GitHub. (La versión de Play Store está obsoleta).
- **Espacio Libre**: Al menos 2GB.
- **Android**: Versión 7.0 o superior recomendada.

---

## 🛠️ 3. Ejecución del Instalador

Clona el repositorio y ejecuta el script principal:

```bash
git clone https://github.com/ANONIMO432HZ/openclaw-android-multiarch.git
cd openclaw-android-multiarch
bash install.sh
```

**Flujo Automático:**

1. Verificación de entorno (Arquitectura, batería, versión de Android).
2. Instalación de motor de ejecución (Node.js nativo o glibc).
3. Parcheo de dependencias nativas (módulos C++ compatibles con Android).
4. Configuración del bloque de entorno en `.bashrc`.

---

## 🌡️ 4. Optimización para Hardware Legado (Legacy)

Si detecta un dispositivo de 32 bits o con poca RAM (<2GB), el sistema aplica estas optimizaciones automáticamente:

- **Thermal Throttling**: Se limita `npm` a 1 solo hilo (`jobs 1`) para evitar que el teléfono se sobrecaliente.
- **Mitigación de OOM (Out of Memory)**: El gateway se inicia con `NODE_OPTIONS="--max-old-space-size=512"` para evitar que el kernel cierre el proceso.
- **Bonjour/mDNS Skip**: Se desactivan servicios de red innecesarios que causan cuelgues al cerrar la aplicación.

---

## 🌐 5. Acceso Remoto al Dashboard (Túnel SSH)

Debido a restricciones de seguridad de WebSockets en Android, la forma más fiable de acceder al chat desde tu PC es mediante un túnel SSH.

### Paso 1: Configurar SSH en Termux

```bash
pkg install openssh
passwd  # Establece una contraseña
sshd    # Inicia el daemon de SSH
```

### Paso 2: Crear el Túnel desde la PC (PowerShell)

```powershell
# Reemplaza u0_aXXX con tu usuario y 192.168.x.x con la IP del móvil
ssh -p 8022 -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 u0_aXXX@192.168.x.x
```

### Paso 3: Iniciar y Entrar

1. En Termux: `oa start`
2. En la PC: Abre `http://localhost:18789` y pega tu token.

---

## 📖 6. Comandos Útiles (Cheat-Sheet)

| Comando | Descripción |
| :--- | :--- |
| `oa status` | Verifica la salud de todos los componentes instalados. |
| `oa start` | Inicia el motor de IA y el servidor WebSocket. |
| `oa onboard` | Configura tus API keys (Anthropic, OpenAI, etc.). |
| `openclaw update` | Actualiza la plataforma a la última versión estable. |
| `sshd` | Permite el acceso remoto mediante el túnel mencionado. |

---

## ❓ 7. Solución de Problemas Comunes

- **"Origin Not Allowed"**: Use la solución del Túnel SSH (Paso 5). No intente cambiar el JSON de configuración manualmente a menos que sepa lo que hace.
- **"Binary Mismatch"**: El instalador lo resuelve solo eligiendo el modo Nativo en lugar de glibc para 32-bit.
- **Cierre Inesperado**: Verifique el consumo de RAM. Cierre aplicaciones pesadas de Android antes de iniciar el gateway.
