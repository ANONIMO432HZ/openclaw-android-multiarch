# Refactor Plan: openclaw-android-multiarch — Agent Task Board

## Estado: EN PROGRESO
## Repo: https://github.com/ANONIMO432HZ/openclaw-android-multiarch

---

## ✅ COMPLETADOS (análisis y preparación)

- [x] Clonar y analizar repo original (AidanPark/openclaw-android)
- [x] Clonar y analizar fork multiarch
- [x] Identificar diferencia estructural (descarga directa vs temporal)
- [x] Decidir mantener método de descarga directa del multiarch
- [x] Preparar todos los archivos corregidos
- [x] Verificar sintaxis bash de todos los archivos (bash -n)
- [x] Crear documentación de cambios

---

## ⬜ PENDIENTES (reemplazar archivos en repo local + push)

### Tarea 1: Reemplazar oa.sh
**Ubicación:** `openclaw-android-multiarch/oa.sh`
**Cambios:**
- Nuevos comandos: `dashboard` (alias: ui), `configure` (alias: setup), `onboard`, `config` (alias: cfg), `doctor` (alias: doc)
- Variable `CYAN` en fallbacks
- `show_help()` reorganizado por categorías
- Cada comando valida que `openclaw` esté instalado

**Verificar que muestre:**
```
  dashboard    Open the OpenClaw Dashboard (Control UI)
  configure    Open the Configuration Wizard
```
NO debe mostrar `ui-config`.

### Tarea 2: Reemplazar verify-install.sh
**Ubicación:** `openclaw-android-multiarch/tests/verify-install.sh`
**Cambios:**
- OA_GLIBC check ahora lee desde `.bashrc` si no está en shell actual
- Debe mostrar: `[PASS] OA_GLIBC=0 (native architecture)` en ARMv7

### Tarea 3: Actualizar mensajes "oa onboard"
**Archivos a modificar (buscar y reemplazar):**
- `scripts/patch-android.sh` → buscar `openclaw onboarding` reemplazar `oa onboard`
- `scripts/install-chromium.sh` → buscar `openclaw onboard` reemplazar `oa onboard`
- `platforms/openclaw/config.env` → buscar `openclaw onboard` reemplazar `oa onboard`

### Tarea 4: Reemplazar README.md
**Ubicación:** `openclaw-android-multiarch/README.md`
**Cambios:**
- Tabla de comandos actualizada con 3 columnas (Option, Aliases, Description)
- Incluye nuevos comandos: dashboard, configure, onboard, config, doctor
- Incluye todos los aliases

### Tarea 5: Commit + Push
```bash
cd openclaw-android-multiarch
git add oa.sh tests/verify-install.sh scripts/patch-android.sh scripts/install-chromium.sh platforms/openclaw/config.env README.md
git commit -m "refactor: new CLI commands (dashboard, configure, onboard, config, doctor) + fix OA_GLIBC verification + update README"
git push origin main
```

### Tarea 6: Verificar instalación limpia
```bash
# En Termux, desinstalar y reinstalar:
oa uninstall
# Luego:
curl -sL https://raw.githubusercontent.com/ANONIMO432HZ/openclaw-android-multiarch/main/bootstrap.sh | bash && source ~/.bashrc
```

**Checklist post-instalación:**
- [ ] `oa -h` muestra `dashboard` y `configure` (NO `ui-config`)
- [ ] `[PASS] OA_GLIBC=0 (native architecture)` en ARMv7
- [ ] `oa dashboard` ejecuta `openclaw dashboard`
- [ ] `oa configure` ejecuta `openclaw configure`
- [ ] `oa onboard` ejecuta `openclaw onboard`
- [ ] `oa doctor` ejecuta `openclaw doctor`
- [ ] `oa update` funciona (git pull)
- [ ] 0 fails en verificación

---

## 📁 Archivos modificados (resumen)

```
openclaw-android-multiarch/
├── oa.sh                          ← comandos CLI nuevos + aliases
├── README.md                      ← tabla de comandos actualizada
├── tests/verify-install.sh        ← fix OA_GLIBC (lee de .bashrc)
├── scripts/patch-android.sh       ← "oa onboard" en vez de "openclaw onboarding"
├── scripts/install-chromium.sh    ← "oa onboard" en vez de "openclaw onboard"
└── platforms/openclaw/config.env  ← POST_INSTALL_MSG actualizado
```

**NO modificar (método de descarga intacto):**
- `bootstrap.sh` — descarga directa en ~/.openclaw-android/
- `install.sh` — 8 steps originales
- `update-core.sh` — git-based
- `scripts/lib.sh` — funciones ARMv7 intactas
- `scripts/setup-cli.sh` — wrapper ~/bin/oa
- `scripts/setup-env.sh` — OA_GLIBC logic intacta

---

## 🔧 Mejoras ARMv7 conservadas (NO tocar)

| Feature | Archivo |
|---|---|
| is_armv7l(), is_low_ram() | scripts/lib.sh |
| OOM prevention (NODE_OPTIONS) | platforms/openclaw/install.sh |
| Skip openclaw update en ARMv7 | platforms/openclaw/install.sh |
| Sharp WASM fallback | platforms/openclaw/install.sh |
| Config 0.0.0.0 binding | platforms/openclaw/install.sh |
| Herramientas ocultas en ARMv7 | install.sh (step 3) |
| patch-android.sh | scripts/patch-android.sh |
| OA_GLIBC=0 para armv7l | scripts/setup-env.sh |
