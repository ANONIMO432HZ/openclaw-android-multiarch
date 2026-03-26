# ⚠️ Troubleshooting & Porting: OpenClaw for Android 7+ (32-bit)

Documentación de errores críticos y parches aplicados para el soporte de hardware legado.

## 1. Error de Arquitectura (Binary Mismatch)

- **Problema:** Scripts que intentan descargar binarios `aarch64` (64-bit) en sistemas `armv7l`.
- **Síntoma:** `Exec format error` o fallos en la verificación de `glibc`.
- **Solución:** Forzar el uso de paquetes nativos de Termux (`pkg install`) y evitar binarios externos pre-compilados para Linux estándar.

## 2. Fallo de Compilación `node-gyp` / `tree-sitter`

- **Problema:** Falta de NDK y RAM insuficiente para compilar módulos nativos de C++.
- **Síntoma:** `npm error code 1` al instalar `gemini-cli` o asistentes de código.
- **Solución:** Instalar dependencias con el flag `--ignore-scripts` o proveer binarios `.node` pre-compilados para ARMv7 en el fork.

## 3. Estrangulamiento Térmico (Thermal Throttling)

- **Problema:** El CPU alcanza los 60°C, activando el estado `health: OVERHEAT`.
- **Síntoma:** El sistema detiene la carga de batería y reduce la frecuencia del reloj del procesador.
- **Solución:**
  - Realizar instalaciones por bloques pequeños.
  - Usar `npm config set jobs 1` para limitar el uso de núcleos durante la instalación.

## 4. Agotamiento de Memoria (OOM)

- **Problema:** El sistema mata el proceso de Node.js por falta de RAM (2GB o menos).
- **Solución:**
  - Deshabilitar servicios pesados (`Chromium`, `code-server`).
  - Iniciar el servidor con limitación de heap: `node --max-old-space-size=512`.

## 5. Acceso Remoto: Error "Origin Not Allowed" (WebSocket)

- **Problema:** El servidor de OpenClaw rechaza conexiones WebSockets desde el PC por motivos de seguridad (CORS/Origin mismatch).
- **Acción fallida:** Intentar editar el JSON con claves no soportadas como `allowAllOrigins` o `allowedOrigins` (causan errores de configuración inválida).
- **Solución Definitiva:** Usar un **Túnel SSH** para mapear los puertos locales del teléfono al PC. De esta forma, el servidor ve la conexión como si fuera local (`127.0.0.1`) y la acepta automáticamente.

### Implementación del Túnel SSH:

1. **En el teléfono (Termux):**
   ```bash
   pkg install openssh
   sshd
   ```

2. **En la PC (PowerShell/CMD):**
   ```powershell
   ssh -p 8022 -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 u0_aXXX@IP_DEL_TEL
   ```

3. **Acceso:** Navegar en el PC a `http://localhost:18789`.