# Refactor Plan: openclaw-android-multiarch

## Objetivo

Consolidar las correcciones al repo multiarch: restaurar la estructura de carpetas del original (AidanPark), mantener todas las mejoras ARMv7, y unificar los comandos del CLI `oa`.

---

## 1. Comandos del CLI `oa` (oa.sh)

### Comandos finales

| Comando | Aliases | Acción |
|---|---|---|
| `oa update` | `up` | Actualiza OpenClaw + tools + patches |
| `oa install` | `inst` | Instalar componentes opcionales |
| `oa start` | `strt` | Iniciar Gateway (background) |
| `oa start:fg` | `strt:fg` | Iniciar Gateway (foreground debug) |
| `oa stop` | `stp` | Detener procesos |
| `oa logs` | `log` | Ver logs en tiempo real |
| `oa dashboard` | `ui` | Abrir Dashboard (Control UI) |
| `oa configure` | `setup` | Wizard de Configuración interactivo |
| `oa onboard` | — | Wizard de Onboarding |
| `oa config` | `cfg` | Config helpers no-interactivos (passthrough) |
| `oa doctor` | `doc` | Health checks + fixes |
| `oa status` | `st` | Estado del sistema y servicios |
| `oa backup` | `bkp` | Backup completo |
| `oa restore` | `rst` | Restaurar backup |
| `oa fix-android` | `fix` | Parches de compatibilidad Android |
| `oa uninstall` | `uninst` | Desinstalar completamente |
| `oa version` | `v`, `-v` | Versión del CLI |
| `oa help` | `-h`, `h` | Ayuda |

### Cambios en `show_help()`

```bash
show_help() {
    banner "OpenClaw Android Professional CLI" "$PURPLE"
    echo "Usage: oa [command]"
    echo ""
    echo "Commands:"
    echo "  update       Update everything (OpenClaw + tools + patches)"
    echo "  install      Install optional components (code-server, tmux, etc.)"
    echo ""
    echo "  start        Start OpenClaw Gateway (Background)"
    echo "  start:fg     Start OpenClaw gateway (Foreground debug)"
    echo "  stop         Stop background processes"
    echo "  logs         View real-time background logs"
    echo ""
    echo "  dashboard    Open the OpenClaw Dashboard (Control UI)"
    echo "  configure    Open the Configuration Wizard (credentials, channels, etc.)"
    echo "  onboard      Run the interactive Onboarding Wizard"
    echo "  config       Non-interactive config helpers (get/set/validate)"
    echo "  doctor       Health checks + quick fixes"
    echo ""
    echo "  status       Show comprehensive system and service status"
    echo "  fix-android  Apply essential Android compatibility patches"
    echo "  backup       Create a full backup of OpenClaw data"
    echo "  restore      Restore OpenClaw data from a backup"
    echo "  uninstall    Completely remove OpenClaw from Android"
    echo "  v|version    Show version info"
    echo "  help|-h      Show this help message"
    echo ""
}
```

### Nuevas funciones

```bash
cmd_dashboard() {
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Opening OpenClaw Dashboard...${NC}"
    openclaw dashboard
}

cmd_configure() {
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Opening Configuration Wizard...${NC}"
    openclaw configure
}

cmd_onboard() {
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Starting Onboarding Wizard...${NC}"
    openclaw onboard
}

cmd_config() {
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    shift
    openclaw config "$@"
}

cmd_doctor() {
    if ! command -v openclaw &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} openclaw not found. Run the installer first."
        exit 1
    fi
    echo -e "${CYAN}Running health checks...${NC}"
    openclaw doctor
}
```

### Case statement final

```bash
case "${1:-}" in
    update|--update|up)       cmd_update "$@" ;;
    install|--install|inst)   cmd_install "$@" ;;
    start|--start|strt)       cmd_start ;;
    start:fg|--start:fg|strt:fg) cmd_start_fg ;;
    stop|--stop|stp)          cmd_stop ;;
    logs|--logs|log)          cmd_logs ;;
    dashboard|--dashboard|ui) cmd_dashboard ;;
    configure|--configure|setup) cmd_configure ;;
    onboard|--onboard)        cmd_onboard ;;
    config|--config|cfg)      cmd_config "$@" ;;
    doctor|--doctor|doc)      cmd_doctor ;;
    status|--status|st)       cmd_status ;;
    backup|--backup|bkp)      cmd_backup "$2" ;;
    restore|--restore|rst)    cmd_restore "$2" ;;
    fix-android|fix)          cmd_fix_android ;;
    uninstall|--uninstall|uninst) cmd_uninstall ;;
    v|version|--version|-v)   echo "oa CLI v$OA_VERSION" ;;
    help|--help|h|"")         show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
```

### Variable CYAN en fallbacks

Agregar al bloque de fallbacks al inicio de `oa.sh`:

```bash
CYAN="${CYAN:-\033[0;36m}"
```

---

## 2. Estructura de carpetas (install.sh)

### Problema

El multiarch NO copia archivos al `$PROJECT_DIR`. El bootstrap descarga el repo
directamente en `$HOME/.openclaw-android/` y lo usa como instalación. Si el repo
cambia o se elimina, la instalación se rompe.

El original (AidanPark) descarga en un directorio temporal, COPIA la estructura
a `$PROJECT_DIR`, y limpia.

### Solución: Step 9 en `install.sh`

Agregar después del step 8 (System Configuration & Services):

```bash
step 9 "Project Directory Structure (OA CLI)"

mkdir -p "$PROJECT_DIR/scripts"
mkdir -p "$PROJECT_DIR/platforms"
mkdir -p "$PROJECT_DIR/patches"

# Copy essential scripts
cp "$SCRIPT_DIR/scripts/lib.sh" "$PROJECT_DIR/scripts/lib.sh"
cp "$SCRIPT_DIR/scripts/setup-env.sh" "$PROJECT_DIR/scripts/setup-env.sh"
[ -f "$SCRIPT_DIR/scripts/backup.sh" ] && cp "$SCRIPT_DIR/scripts/backup.sh" "$PROJECT_DIR/scripts/backup.sh"

# Copy platform config
rm -rf "$PROJECT_DIR/platforms/$SELECTED_PLATFORM"
cp -R "$SCRIPT_DIR/platforms/$SELECTED_PLATFORM" "$PROJECT_DIR/platforms/$SELECTED_PLATFORM"

# Copy uninstall script
cp "$SCRIPT_DIR/uninstall.sh" "$PROJECT_DIR/uninstall.sh"
chmod +x "$PROJECT_DIR/uninstall.sh"

# Copy oa to PREFIX/bin (direct execution, like original)
cp "$SCRIPT_DIR/oa.sh" "$PREFIX/bin/oa"
chmod +x "$PREFIX/bin/oa"

# Copy oaupdate
cp "$SCRIPT_DIR/update.sh" "$PREFIX/bin/oaupdate"
chmod +x "$PREFIX/bin/oaupdate"

echo -e "${GREEN}[OK]${NC}   Project directory structure created"
```

### Cambios en TOTAL_STEPS

Cambiar de 8 a 9:

```bash
TOTAL_STEPS=9
```

Y actualizar el banner del step 8 para que diga "8/9" en vez de "8/8".

---

## 3. Bootstrap (bootstrap.sh)

### Problema

El multiarch descarga en `$HOME/.openclaw-android/` (el PROJECT_DIR final),
mientras que el original descarga en `$HOME/.openclaw-android/installer/` (temporal).

### Solución

Cambiar `INSTALL_DIR` a directorio temporal y limpiar después:

```bash
INSTALL_DIR="$HOME/.openclaw-android/installer"

# ... descargar ...

bash "$INSTALL_DIR/install.sh"

chmod +x "$INSTALL_DIR/uninstall.sh"
rm -rf "$INSTALL_DIR"
```

---

## 4. Mejoras del Multiarch a CONSERVAR

No tocar estas funcionalidades — son las correcciones que hiciste para ARMv7:

| Archivo | Mejora |
|---|---|
| `scripts/lib.sh` | `is_armv7l()`, `is_low_ram()`, `IS_ARMV7L`, `step()`, `banner()`, `check_tool_installed()` |
| `scripts/setup-env.sh` | `OA_GLIBC=0` para armv7l, `OA_GLIBC=1` para aarch64 |
| `platforms/openclaw/install.sh` | Skip `openclaw update` en ARMv7, Sharp WASM fallback, config 0.0.0.0 binding, OOM prevention con `NODE_OPTIONS` |
| `scripts/patch-android.sh` | Parchea core para permitir onboarding en Termux |
| `scripts/setup-cli.sh` | Wrapper `~/bin/oa` → `$PROJECT_DIR/oa.sh` |
| `scripts/setup-shell.sh` | PATH y `OPENCLAW_ANDROID_DIR` en .bashrc |
| `install.sh` (step 3) | Ocultar herramientas incompatibles en ARMv7 |
| `install.sh` (step 5) | `install-infra.sh` vs `install-infra-deps.sh`, OOM prevention |

---

## 5. Orden de implementación

1. ✅ **oa.sh** — Cambiar nombres de comandos + agregar nuevos (YA LISTO)
2. ⬜ **install.sh** — Agregar step 9 + cambiar TOTAL_STEPS a 9
3. ⬜ **bootstrap.sh** — Cambiar a directorio temporal
4. ⬜ **Verificar** — `bash -n` en todos los .sh modificados
5. ⬜ **Commit + push** al repo multiarch

---

## 6. Archivos modificados

```
openclaw-android-multiarch/
├── oa.sh              ← COMANDOS NUEVOS (listo)
├── install.sh         ← STEP 9 (pendiente)
├── bootstrap.sh       ← DIRECTORIO TEMPORAL (pendiente)
└── (sin cambios en scripts/, platforms/, patches/)
```
