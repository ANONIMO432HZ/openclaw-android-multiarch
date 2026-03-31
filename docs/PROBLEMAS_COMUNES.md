# 🛠️ Problemas Comunes y Soluciones — OpenClaw Termux Edition

Esta guía contiene soluciones rápidas a errores frecuentes durante el uso de la CLI `oa` en Android/Termux.

---

## 1. Errores de Sintaxis (`syntax error: unexpected end of file`)

**Síntoma:** Intentas ejecutar `oa update` o cualquier comando y recibes un error como:
`line XXX: syntax error: unexpected end of file from 'if' command on line YYY`

**Causa:** Una actualización se interrumpió o el script se descargó de forma incompleta, dejando bloques de código abiertos (sin el `fi` o `}`).

**Solución (Forzar Re-instalación):**
Ejecuta este comando para descargar la versión estable oficial y sobreescribir la dañada:
```bash
curl -L https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/oa.sh -o ~/.openclaw-android/oa.sh && chmod +x ~/.openclaw-android/oa.sh && ln -sf ~/.openclaw-android/oa.sh $PREFIX/bin/oa
```

---

## 2. Error de Variable no Definida (`unbound variable`)

**Síntoma:** El script se detiene diciendo algo como `USER: unbound variable`.

**Causa:** El script usa `set -u` (modo estricto) y algunas variables de entorno (como `USER` o `PREFIX`) no están exportadas en tu terminal actual.

**Solución:**
1. Asegúrate de tener las variables en tu `.bashrc`: `oa fix-env`.
2. Si el error persiste, usa la versión más reciente de `oa.sh` que incluye fallbacks automáticos para estas variables.

---

## 3. Acciones Remotas vía Antigravity (Mantenimiento SSH)

Si necesitas que un agente de IA realice el mantenimiento o tú mismo quieras gestionar el sistema desde tu PC usando tu llave SSH de Antigravity:

### A. Comando de acceso rápido (para ver estado)

```powershell
ssh -i C:\Users\TU_USUARIO\.ssh\id_antigravity -p 8022 -o StrictHostKeyChecking=no u0_a143@TU_IP_LOCAL "oa status"
```

### B. Comando de acceso remoto para agentes IA (Terminal interactiva)

```powershell
ssh -i C:\Users\TU_USUARIO\.ssh\id_antigravity -p 8022 -o StrictHostKeyChecking=no u0_a143@TU_IP_LOCAL
```

### C. Comando de "Recuperación Total" (One-Liner)

Para cuando nada funciona, este comando reinstala el core, limpia el repo y lanza un chequeo de estado:
```powershell
ssh -i C:\Users\TU_USUARIO\.ssh\id_antigravity -p 8022 -o StrictHostKeyChecking=no u0_a143@TU_IP_LOCAL "echo '--- RE-INSTALLING OPENCLAW CORE ---' && npm install -g openclaw@latest --no-audit --no-fund && echo '--- FIXING PATHS ---' && ln -sf $(npm config get prefix)/bin/openclaw $PREFIX/bin/openclaw && echo '--- FINAL STATUS CHECK ---' && openclaw --version && cd ~/.openclaw-android && git reset --hard origin/main && git pull origin main && oa status"
```

> [!IMPORTANT]
> Cambia `u0_a143@TU_IP_LOCAL` por tu usuario de Termux e IP local real (`ip addr show`).

---

## 4. El servicio `start:sv` no arranca (`[FAIL]`)

**Síntoma:** Ejecutas `oa srt:sv` y recibes un error de timeout.

**Causa:** El supervisor `runit` puede tardar unos segundos en inicializar el proceso. En dispositivos lentos, puede exceder el tiempo de espera.

**Solución:**
- Hemos aumentado el tiempo de espera a **25 segundos** en la versión actual.
- Verifica el log del servicio manualmente para ver el error real:
  ```bash
  cat ~/.openclaw-android/logs/current
  ```
- O intenta el arranque manual en segundo plano: `oa start`.

---

## 5. Accesos a la UI (`oa ui`)

**Síntoma:** No puedes acceder al panel desde el navegador de tu computadora.

**Causa:** Bloqueos de red o falta del túnel SSH.

**Solución:**
Ejecuta `oa ui` y usa el comando de túnel sugerido en pantalla:
```bash
ssh -L 18789:127.0.0.1:18789 -L 18791:127.0.0.1:18791 -p 8022 [USUARIO]@[IP]
```
Luego entra en tu PC a: `http://localhost:18789/#token=TU_TOKEN`

---

## 6. Errores inusuales de Runit/Termux-Services (`file does not exist`)

**Síntoma:** Al usar `oa start:sv` o `oa stop:sv`, la terminal o tu conexión SSH de Antigravity arroja el error:
`fail: openclaw-gateway: unable to change to service directory: file does not exist`

**Causa:** El paquete `termux-services` exige que exista la variable de entorno `SVDIR` seteada internamente para localizar `/var/service`. Si corres scripts de forma no interactiva (ej: vía SSH directo) y esta variable no carga, `sv` intentará buscar en la raíz de Android (que no existe) provocando el fallo.
**Solución Permanente Implementada:** Inyectamos `export SVDIR="$PREFIX/var/service"` globalmente en `~/.bashrc` y de forma forzosa en la validación inicial de cada comando de la CLI de `oa`.

---

## 7. Falsos Positivos: Servicio reportado "En Ejecución" cuando está detenido

**Síntoma:** Al detener el servicio correctamente con `oa stop:sv`, al revisar los procesos mediante `oa status` la herramienta sigue diciendo `Status: Running (Manual mode)` o simplemente `Running`.

**Causa (Bugs superpuestos de Runit):**
1. `sv status` imprime el estado normal del servicio *y el de sus logs*. Cuando el servicio cae, el daemon de logs (`svlogd`) sigue activo, devolviendo el string `run: log:`, lo que engañaba a filtros simples (ej. `grep -q "run:"`).
2. El supervisor estricto de Termux (`runsv`) que mantiene vivo el servicio se llama `runsv openclaw-gateway`. En un escaneo manual de procesos con `pgrep -f "openclaw"`, el propio supervisor era detectado erróneamente como si el servidor Node.js siguiera vivo y originaba un Falso Positivo "Manual".

**Solución Permanente Implementada:** 
- Aislamos el grep a buscar exactamente la cadena `^run: openclaw-gateway:` ignorando al daemon de logs.
- Refinamos el patrón `pgrep` omitiendo explícitamente `runsv` para garantizar que la CLI solo alerte si el proceso **Node.js** genuino (y no sus wrappers de sistema) está funcionando.
