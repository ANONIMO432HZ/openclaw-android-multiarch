# OpenClaw en Android

[English](README.md) | [Español](README.es.md) | [한국어](README.ko.md) | [**Changelog**](CHANGELOG.md)

<img src="docs/images/openclaw_android.jpg" alt="OpenClaw en Android">

![Android 7.0+](https://img.shields.io/badge/Android-7.0%2B-brightgreen)
![Termux](https://img.shields.io/badge/Termux-Requerido-orange)
![Sin proot](https://img.shields.io/badge/proot--distro-No%20Requerido-blue)
![Licencia MIT](https://img.shields.io/github/license/ANONIMO432HZ/openclaw-android-multiarch)
[![Version](https://img.shields.io/badge/version-1.2.2.1-blue.svg?style=for-the-badge)](https://github.com/ANONIMO432HZ/openclaw-android-multiarch)

Porque Android merece una terminal de verdad.

> **🎯 Propósito de este Fork:**
> Este repositorio es un fork especializado del proyecto oficial [AidanPark/openclaw-android](https://github.com/AidanPark/openclaw-android). Su único propósito es **mantener la compatibilidad completa de instalación y operación para OpenClaw directamente desde dispositivos armv7 (32 bits) y más nuevos dentro de Termux (sin root)**.
> **NO** proporcionamos mantenimiento para la APK de Android, el panel de control de React UI (`android/`), ni ninguna otra característica que no esté estrictamente relacionada con mantener el gateway nativo CLI funcionando de manera óptima en entornos Termux.

## 📱 Casos de Éxito

### Estudio de Caso: Motorola Moto G6 (Legado de 32 bits)

* **Créditos**: Gateway basado en [openclaw/android](https://github.com/AidanPark/openclaw-android). Proxy Inteligente ([OmniBrain-AI-Proxy-Smart](https://github.com/ANONIMO432HZ/OmniBrain-AI-Proxy-Smart)) refactorizado por el autor a partir de una demo de `midudev`.
* **Dispositivo**: Moto G6 (XT1925) - Snapdragon 450, 2GB RAM.
* **Arquitectura**: `armv7l` (32 bits).
* **Resultado**: OpenClaw Gateway + Dashboard totalmente funcionales.
* **Estrategia**: Modo "Native Lite" (Sin proot), SSH Tunneling para el Dashboard, y [OmniBrain-AI-Proxy-Smart](https://github.com/ANONIMO432HZ/OmniBrain-AI-Proxy-Smart) como proxy para ahorrar RAM local.
* **Guía Completa**: Mira nuestro **[Ejemplo de Despliegue en Moto G6](docs/moto-g6-deploy-example.md)** para una guía sobre cómo configurar el **Proveedor Personalizado** con el modelo **`auto`** para enrutamiento inteligente.

## Sin necesidad de instalar Linux

El enfoque estándar para ejecutar OpenClaw en Android requiere instalar proot-distro con Linux, lo que añade entre 700MB y 1GB de sobrecarga. OpenClaw en Android elimina esto mediante:

1. **Modo glibc (aarch64)**: Instalando solo el enlazador dinámico glibc (ld.so), permitiéndote ejecutar OpenClaw sin una distribución Linux completa.
2. **Modo Nativo (armv7l)**: Usando paquetes nativos de Termux para dispositivos antiguos de 32 bits (Android 7+), maximizando la compatibilidad y el rendimiento.

> 🚀 **¿Buscas una guía detallada?** Consulta nuestra **[Guía Completa de Configuración de Termux](docs/setup-termux.md)** para instrucciones paso a paso y consejos para hardware antiguo.

| | Estándar (proot-distro) | Este proyecto |
|---|---|---|
| Sobrecarga de almacenamiento | 1-2GB (Linux + paquetes) | ~200MB |
| Tiempo de configuración | 20-30 min | 3-10 min |
| Rendimiento | Más lento (capa proot) | Velocidad nativa |
| Pasos de configuración | Instalar distribución, configurar Linux, instalar Node.js... | Ejecutar un solo comando |

## Requisitos

* Android 7.0+ (Android 10+ recomendado)
* ~1GB de espacio libre
* Conexión Wi-Fi o datos móviles

## Qué hace el Instalador

El instalador resuelve automáticamente las diferencias entre Termux y el Linux estándar. Todo se maneja de forma automática con un solo comando:

1. **Entorno glibc** — Instala el enlazador dinámico glibc (vía pacman) para que los binarios estándar de Linux funcionen sin modificación.
2. **Node.js (glibc)** — Descarga Node.js oficial y lo envuelve con un script cargador ld.so.
3. **Modo Ultra-Light (ARMv7)** — Gestión inteligente de memoria para dispositivos con <2GB de RAM.
4. **Diagnósticos Automáticos** — Sistema `oa doctor` integrado para solucionar problemas comunes de Termux.
5. **Seguridad Pre-Actualización** — Respaldos automáticos de datos antes de cualquier actualización.

## Configuración paso a paso

### Paso 1: Inicializar Termux

Abre la app Termux y pega el siguiente comando para instalar curl y git.

```bash
pkg update -y && pkg install -y curl git
```

### Paso 2: Instalar OpenClaw

Pega el siguiente comando en Termux. Tienes dos opciones:

#### Opción A: Instalación en un paso (Recomendado)

Este comando maneja carpetas preexistentes y actualiza automáticamente usando nuestro "sensor" de arranque.

```bash
bash <(curl -sL https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/bootstrap.sh)
```

#### Opción B: Instalación Manual (Git)

Para aquellos que prefieren un despliegue tradicional basado en Git.

```bash
git clone --depth=1 --branch main https://github.com/ANONIMO432HZ/openclaw-android-multiarch.git ~/.openclaw-android && bash ~/.openclaw-android/install.sh && source ~/.bashrc
```

### Paso 3: Configuración inicial (`onboard`)

Como se indica al finalizar la instalación, ejecuta:

```bash
oa onboard
```

### Paso 4: Iniciar OpenClaw (Gateway)

Una vez completada la configuración, inicia el gateway. Recomendamos el **modo de fondo** (background) para que se mantenga estable aunque cambies de aplicación:

```bash
oa start
```

Puedes verificar que el gateway esté funcionando correctamente revisando los logs:

```bash
oa logs
```

> **Consejo**: Si prefieres verlo directamente en pantalla para depuración, usa `oa start:fg`. Para detenerlo todo, usa `oa stop`.

## Gestión de Multi-Sesión (Servicio)

Para una estabilidad de nivel de producción, recomendamos usar la integración con `termux-services` (runit). Esto asegura que el gateway se reinicie automáticamente si falla y gestiona los logs de manera eficiente.

1. **Iniciar Servicio**:
    ```bash
    oa start:sv
    ```
    * **Espera Inteligente**: Incluye un sistema de espera de doble bucle (máx 90s) que monitorea los logs en tiempo real para confirmar cuando Node.js está "escuchando" completamente.
    * **Verificación de Puerto**: Ahora verifica que el socket TCP esté realmente vinculado antes de declarar éxito, eliminando condiciones de carrera en kernels ARMv7 lentos.

2. **Detener Servicio**:
    ```bash
    oa stop
    ```
    * **Parada Simétrica**: `oa stop` detectará si el servicio está activo, lo detendrá y luego procederá a limpiar cualquier proceso "zombie" o manual restante, garantizando un estado 100% limpio.

---

## Referencia de Comandos CLI (`oa`)

Después de la instalación, el comando `oa` estará disponible para gestionar tu sistema:

| Opción | Alias | Descripción |
| :--- | :--- | :--- |
| `oa update` | `up` | **Actualización Profesional**: OpenClaw-Core (Latest o Stable) + Herramientas + Parches |
| `oa self-update` | `upgrade` | **Sincronización Robusta**: Scripts CLI y parches (con auto-stash) |
| `oa install-tools` | `inst` | Instala herramientas opcionales (tmux, code-server, etc.) |
| `oa uninstall-tools` | — | Desinstala herramientas opcionales de forma selectiva |
| `oa start` | — | Inicia el Gateway en segundo plano (Manual - nohup) |
| `oa start:sv` | `strt` | Inicia el Gateway vía **termux-services** (Espera Inteligente 90s) |
| `oa stop` | `stp` | **Parada Simétrica**: Detiene servicio y limpia procesos "Zombie" |
| `oa logs` | `log` | Ver logs en tiempo real del fondo/servicio |
| `oa ui` | `dashboard` | Abre el Panel de Control de OpenClaw |
| `oa ui-config` | `config-wizard` | Asistente de Configuración interactivo |
| `oa onboard` | — | Ejecuta el Asistente de Bienvenida oficial |
| `oa doctor` | `doc` | **Chequeo de Salud**: Diagnostica y repara errores comunes |
| `oa status` | `st` | **Estado Inteligente**: Diagnóstico de sistema y puertos |
| `oa backup` | `bkp` | Crea un respaldo completo de los datos (`.tar.gz`) |
| `oa restore` | `rst` | Restauración interactiva de respaldos anteriores |
| `oa uninstall` | `uninst` | Elimina completamente OpenClaw de Android |
| `oa version` | `v` | Muestra la versión (Actual: 1.2.2.1) |

## Actualización

```bash
oa update && source ~/.bashrc
```

Este comando actualiza todos los componentes instalados de una sola vez. Los componentes que ya estén actualizados se omiten automáticamente. Es seguro ejecutarlo varias veces.

## Respaldos y Restauración

Para crear un respaldo:

```bash
oa backup
```

Los respaldos se guardan en `~/.openclaw-android/backup/`. Para restaurar uno anterior:

```bash
oa restore
```

## Rendimiento

> [!NOTE]
> El comando `oa status` puede sentirse más lento que en un PC debido a la velocidad de lectura de la memoria interna de Android. Sin embargo, **una vez que el gateway está funcionando, no hay diferencia**. El proceso permanece en RAM y las respuestas de IA se procesan en servidores externos, por lo que la velocidad es idéntica a la de un ordenador.

## Licencia

MIT
