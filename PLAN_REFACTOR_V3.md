# 🚀 Plan de Refactorización V3: OpenClaw Termux Edition

## Objetivo Principal
Transformar el fork actual (que arrastra código innecesario heredado del [upstream original](https://github.com/AidanPark/openclaw-android)) en un proyecto **exclusivo, ultraligero y nativo para Termux llamado "OpenClaw Termux Edition"**. 
El repositorio dejará de intentar ser o mantener la App de Android (APK/UI) y se convertirá en la solución definitiva para mantener compatibilidad en línea de comandos (CLI `oa`) tanto para ecosistemas legacy (armv7 de 32 bits) como aarch64 (64 bits).

---

## 🗑️ Fase 1: Limpieza Quirúrgica (Eliminación de Peso Muerto)

El peso y el ruido cognitivo del repositorio provienen de herramientas de compilación que no usaremos.

1. **Eliminar el directorio `android/`**: Contiene todo el frontend de la UI, assets de React y código específico de Android Studio. Ocupa gran parte del repo y ralentiza `git`.
2. **Eliminar `.github/workflows/` (Relacionado a APK)**: Borraremos o ajustaremos las acciones de compilación en la nube dedicadas a ensamblar e inyectar código en el APK.
3. **Limpieza en Scripts de Instalación**: Revisaremos archivos como `bootstrap.sh`, `install.sh` y el nuevo `oa.sh` para garantizar que no existan validaciones que busquen archivos del APK borrado (en principio ya limpiamos esto, pero se hará una doble verificación).

---

## 📘 Fase 2: Rebranding de Documentación (Nuevas Reglas de Juego)

La documentación debe dejar claro al visitante en 5 segundos qué es este proyecto.

1. **`README.md` y `README.ko.md`**: 
   - Cambiar el título a algo como **OpenClaw on Android: Termux Edition**.
   - Añadir un "Disclaimer" inmenso: *"¿Buscas la App con interfaz gráfica (APK)? Ve al [repositorio oficial de AidanPark](https://github.com/AidanPark/openclaw-android). Este fork está estrictamente dedicado a brindar el motor backend para Termux y dar soporte optimizado a procesadores legacy armv7 y aarch64 por CLI".*
2. **`como-actualizar-upstream.md`**: 
   - Actualizar las políticas de "merge" (fusión de código). Advertir explícitamente al desarrollador (tú) que, al hacer `git fetch upstream`, debe ignorar por completo las modificaciones del entorno gráfico o de la carpeta `android/` del autor original, fusionando únicamente actualizaciones a nivel de `scripts/`, dependencias o núcleo de OpenClaw.

---

## 🛠️ Fase 3: Pruebas de Estabilidad CLI

Asegurarnos de que nuestra CLI `oa` (que ya está unificada y estructurada) no presenta regresiones tras la eliminación de los archivos pesados.

1. Ejecución de `oa install` y `oa update` (simulados) para asegurar que el ruteo interno no falla.
2. Comprobación que el clonado ligero mejora sustancialmente la velocidad de descarga en nuevos equipos.

---

## 📝 Aprobación y Siguientes Pasos (User Review Required)

> [!IMPORTANT]
> **Usuario:** Revisa este plan. Si estás de acuerdo con borrar permanentemente los directorios `android/` y los `.github/workflows` que compilan el APK convirtiendo este repo oficialmente en un CLI Tool puro, aprueba el plan y procederé con la Fase 1 inmediatamente.
