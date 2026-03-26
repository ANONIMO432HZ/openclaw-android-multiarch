# ⚠️ Troubleshooting & Porting: OpenClaw for Android 7+ (32-bit/armv7)

Este documento centraliza las soluciones técnicas y parches necesarios para ejecutar agentes de IA modernos en hardware heredado (legacy) con arquitectura ARM de 32 bits.

## 1. Error de Arquitectura: "Exec format error"
- **Problema:** Los scripts de instalación estándar de OpenClaw/Node-Glibc descargan binarios `aarch64` (64-bit) por defecto.
- **Detección:** Ejecutar `uname -m` en Termux. Si devuelve `armv7l`, no puedes usar binarios de Linux estándar precompilados.
- **Solución:** Usar Node.js nativo de Termux: `pkg install nodejs-lts`. 

## 2. Fallo Crítico de Base de Datos (SQLite)
- **Problema:** Módulos de persistencia como `better-sqlite3` fallan al compilar/instalar en arquitecturas de 32 bits en Android.
- **Síntoma:** `node-gyp rebuild failed` o `npm err! code 1` durante la instalación.
- **Solución:** Utilizar una capa de persistencia basada en **`sql.js` (WebAssembly)** en lugar de binarios nativos. 

## 3. Optimización de RAM y Gestión Térmica

- **Problema:** Dispositivos con 1-2GB de RAM pueden bloquearse bajo carga extrema.
- **Acción:** El sistema puede calentarse durante la **instalación inicial** de dependencias pesadas.
- **Solución:** 
  - Limitar el uso de memoria de Node: `node --max-old-space-size=512`.
  - El uso normal del gateway es ligero, eficiente y térmicamente estable. La temperatura solo sube durante la instalación de dependencias pesadas, lo cual es un evento de una sola vez.

## 4. Estrategia de Proxy para Menor Carga
- **Problema:** Procesar el enrutamiento y la cascada de modelos consume mucha CPU en hardware viejo.
- **Solución Dinámica:** Delegar la inteligencia del agente a un servidor proxy como [OmniBrain-API](https://github.com/AidanPark/OmniBrain-API).
- **Esquema:** `OpenClaw (Android)` -> `OmniBrain-API (Proxy)` -> `AI Providers (Cloud)`.

## 5. Acceso Remoto: Túneles SSH
- **Problema:** El error `Origin not allowed` bloquea el dashboard al entrar por la IP local.
- **Solución Definitiva:** La única forma segura de puentear el CORS de OpenClaw en Android es usar un túnel SSH.
- **Comando en la PC:**
  ```bash
  ssh -p 8022 -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 u0_aXXX@IP_DEL_TEL
  ```
- **Conexión:** Navegar a `http://localhost:18789`.

---

> [!TIP]
> **Lección Aprendida:** Un dispositivo antiguo (32-bit) no puede ser un entorno de desarrollo completo, pero es un **fantástico "AI Gateway"** si se configura de forma ligera.