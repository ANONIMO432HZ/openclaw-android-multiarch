# 🛡️ Arquitecturade Actualización Inteligente V2 (OpenClaw Android)

Este documento detalla el plan de implementación para la **Versión 2** del sistema de actualización (`oa --update`). El objetivo es transformar un proceso de "fuerza bruta" en una operación quirúrgica, segura y resiliente.

---

## 🎯 Objetivos Principales

1. **Instalaciones Atómicas**: Nunca comprometer el sistema en funcionamiento hasta que la nueva versión esté validada.
2. **Guardian de Servicio**: Detectar gateways activos y solicitar/forzar una detención segura antes del update para evitar colisiones de archivos.
3. **Setup Inicial Veloz**: Reutilizar los artefactos pre-parcheados en el [install.sh](file:///c:/PROYECTOS/SPACE-WORKFLOW/openclaw-android-bcp/install.sh) para que el primer uso sea instantáneo.
4. **Detección de Idempotencia**: Evitar re-descargas y re-parcheos innecesarios (ahorro de disco y tiempo).
5. **Sensores de Compatibilidad**: Detectar cambios estructurales en OpenClaw que invaliden nuestros parches de Android.
6. **Smoke Testing**: Validar la ejecución binaria en un entorno aislado (`sandbox`) antes del despliegue final.
7. **Pre-patched Artifacts (CI/CD)**: Mover el "trabajo sucio" del parcheo (45+ min) a GitHub Actions para que el móvil solo descargue un paquete verificado (20 seg).

---

## 🏗️ Flujo de Implementación (Algoritmo V2)

### 1. Fase de Reconocimiento y Selección de Origen (Update & Install)

* **Consulta Remota Inteligente**: Verificar versiones disponibles en NPM (Original) y GitHub Releases (Pre-parcheada).
* **Comparación Local**: Verificar contra `~/.openclaw-android/.version_installed`.
* **Service Check (Solo en Update)**:
  * Detectar si `openclaw-gateway` está corriendo.
  * Pedir confirmación: *"Gateway activo detectado. ¿Detener para actualizar? [Y/n]"*.
  * Si se aprueba, ejecutar `oa stop`. Si falla el stop resiliente, abortar el update para evitar corrupción y solicitar cierre manual.
* **Menú de Usuario (Reutilizable)**:
  * `Opción 1: [Recomendado] Descargar Pre-parcheado (Verificado en GitHub) [Veloz]`.
  * `Opción 2: Recompilar/Parchear Localmente (NPM Original) [Lento]`.
  * `Opción 3: Mantener actual [Estable]`.
* **Integración en Install.sh**: El instalador de primer uso usará la `Opción 1` por defecto para garantizar el éxito en dispositivos de gama baja.

### 2. Infraestructura remota (GitHub Actions)

* **Trigger Semanal/NPM**: Monitorear nuevas versiones de OpenClaw.
* **Build Runner**: Aplicar `apply-patches.sh` en un entorno virtual Linux x64/arm64.
* **Automated QA**: Ejecutar el `Smoke Test` en la nube.
* **Release Management**: Si los tests pasan, subir el [.tar.gz](file:///c:/PROYECTOS/SPACE-WORKFLOW/backups/2026-03-26T22-19-59.000Z-openclaw-backup.tar.gz) pre-parcheado a las GitHub Releases de `ANONIMO432HZ/openclaw-android-multiarch`.

### 3. Fase de Aislamiento y Despliegue (Local)

* **Sandbox**: Descargar el artefacto elegido (o instalar vía NPM) en `/tmp/oa-sandbox/`.
* **Sensing (Solo si es NPM)**: Ejecutar parcheo local y verificar contador de "Misses".
* **Swap**: Si la prueba de humo local (`oa-sandbox/bin/openclaw --version`) es exitosa, intercambiar con la carpeta de producción.

### 4. Prueba de Humo (Smoke Test)

* **Ejecución Aislada**: Intentar correr `node ./bin/openclaw --version` dentro del sandbox usando el `ld.so` configurado.
* **Validación de Salida**: Si el comando responde con la versión, la integridad binaria está confirmada.

### 5. Hot Swap (Intercambio en Caliente)

* **Cierre de Gateway**: `sv stop openclaw-gateway` (usando el nuevo `stop` resiliente).
* **Sustitución**: `rm -rf $PREFIX/lib/node_modules/openclaw` && `mv /oa-sandbox $PREFIX/lib/node_modules/openclaw`.
* **Marcador**: Actualizar `~/.openclaw-android/.version_installed`.

---

## 📋 Lista de Tareas para Desarrollo

* [ ] Crear el archivo `STABLE_VERSION` en el repositorio maestro de GitHub.
* [ ] Refactorizar [update-core.sh](file:///c:/PROYECTOS/SPACE-WORKFLOW/openclaw-android-bcp/update-core.sh) para soportar la lógica de `/tmp/oa-sandbox`.
* [ ] Implementar el sistema de contadores de parches (Sensores) en `apply-patches.sh`.
* [ ] Añadir validación de salida en el Smoke Test para detectar errores de arquitectura (WASM/Native).
* [ ] Integrar prompts de decisión para el usuario ("Se detectó incompatibilidad, ¿instalar versión estable sugerida?").

---

## ⚓ Puntos de Recuperación (Rollback)

En caso de fallo catastrófico en el Smoke Test, el script simplemente borrará el Sandbox y dejará el sistema actual intacto, notificando al usuario que la actualización no fue posible por razones de seguridad.

---
*Plan diseñado por Antigravity para una infraestructura móvil de alto rendimiento.*
