Aquí tienes un archivo `context.md` detallado que resume técnicamente todo el proceso que hemos realizado. Este archivo es ideal para que cualquier otra IA (como Cursor, Windsurf o el propio OpenClaw) entienda exactamente dónde estás parado y no intente sugerirte pasos que ya fallaron por limitaciones de hardware.

Puedes crearlo en tu Termux con: `nano context.md` (pegas el contenido y guardas con Ctrl+O, Enter, Ctrl+X).

---

# Contexto del Proyecto: OpenClaw en Moto G6 (Alium)

## 📱 Hardware & Entorno
- **Dispositivo:** Motorola Moto G6 (XT1925).
- **Arquitectura:** `armv7l` (32-bit). *Nota: El sistema soporta binarios de 32 bits, lo que limita ciertas herramientas de 64 bits (aarch64).*
- **Procesador:** Snapdragon 430 (8 núcleos).
- **Memoria RAM:** 2GB (Límite crítico de recursos).
- **Almacenamiento:** ~23GB disponibles.
- **Sistema Operativo:** Android 9 (Stock) ejecutando **Termux** (versión reciente).
- **Estado Térmico:** Tendencia al sobrecalentamiento (registrados 60°C en instalación). Se recomienda uso sin funda y sin carga simultánea durante procesos pesados.

## 🛠️ Software & Stack Actual
- **Entorno Nativo:** Se eliminó `proot-distro (Ubuntu)` para ahorrar RAM y evitar capas de emulación innecesarias.
- **Node.js:** `v24.14.1` (Instalado vía `pkg install nodejs`).
- **Gestor de Paquetes:** `npm 11.12.0`.
- **Repositorio Utilizado:** [AidanPark/openclaw-android](https://github.com/AidanPark/openclaw-android).
- **Herramientas Instaladas:**
  - `tmux` (Multiplexor de terminal).
  - `ttyd` (Terminal vía Web en puerto `7681`).
  - `dufs` (Servidor de archivos ligero).
  - `android-tools` (ADB local).
  - `gemini-cli` (Instalación parcial, falló compilación de `tree-sitter-bash` por NDK, pero no es crítico).

## 🚀 Estado del Setup (Avance)
1. **Limpieza:** Se eliminaron instalaciones previas globales de `openclaw-termux`, el bypass de Bionic y restos de proot.
2. **Configuración de Red:** El dispositivo tiene la IP local `192.168.0.193`.
3. **OpenClaw Core:** Instalado exitosamente mediante el script `install.sh` del repositorio de AidanPark (seleccionando solo componentes ligeros).
4. **Inicialización:** Se ejecutó `openclaw setup` creando correctamente el archivo de configuración en `~/.openclaw/openclaw.json`.
5. **Comando de Arranque:** El comando identificado para iniciar el servidor es `openclaw gateway`.

## ⚠️ Restricciones & Decisiones Técnicas
- **NO Chromium:** Se rechazó la instalación por consumo excesivo de RAM (>400MB).
- **NO Code-Server / OpenCode:** Rechazados para evitar el colapso del procesador Snapdragon 430.
- **Modo de Operación:** El gateway debe correr en `--gateway.mode=local` para maximizar la estabilidad.
- **Binding de Red:** Se debe forzar el host `0.0.0.0` y el puerto `18789` para permitir el acceso desde la PC externa.

## 📋 Pendientes Proóximos
- Validar la persistencia de la configuración en `~/.openclaw/openclaw.json`.
- Iniciar el servicio con `termux-wake-lock` activo.
- Vincular la **Gemini API Key** en la interfaz web o mediante el archivo de configuración.
- Pruebas de conexión desde el navegador de la PC (`http://192.168.0.193:18789`).

---

**Nota de uso:** Este contexto debe ser proporcionado a cualquier asistente de código para evitar la reinstalación de paquetes de 64 bits o herramientas de automatización de navegador (Puppeteer/Chromium) que congelarían el Moto G6.