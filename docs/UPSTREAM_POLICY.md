# 🚀 Política de Upstream: OpenClaw Termux Edition (v1.1.3)

Esta es la guía operativa para mantener el fork sincronizado con el repositorio original de **AidanPark/openclaw-android** sin comprometer la ligereza y estabilidad de la **v1.1.3 (Termux Edition)**.

---

## 🎯 Nuestra Arquitectura (V3 Purification)

Hemos "extirpado" quirúrgicamente el código del APK para convertirnos en una **CLI Pura**. Solo fusionamos:
- ✅ Cambios en el motor de OpenClaw.
- ✅ Mejoras en los parches de compatibilidad (ej: el DNS-Stub de la v0.4.0).
- ✅ Actualizaciones de dependencias core.

**REGLA DE ORO:** Cualquier carpeta `android/`, `app/` o flujos de `workflows` del original **no** deben ser integrados.

---

## 🛠️ Procedimiento de Sincronización Profesional

### 1. Preparación de Entorno
```bash
git fetch upstream
git checkout main
```

### 2. El Merge Estratégico (Hybrid Sync)

No hagas un merge ciego. Recomendamos:
```bash
# 1. Traer solo los parches de compatibilidad mejorados
git checkout upstream/main -- patches/glibc-compat.js

# 2. Auditar el package.json (extraer versiones, no el archivo entero)
git show upstream/main:android/www/package.json
```

### 3. Resolución de Conflictos Estructurales
Si hay conflictos en `oa.sh` o `lib.sh`:
- **Tuyo**: Nuestras constantes (`LIME`, `v1.1.3`) y rutas de `.openclaw-android`.
- **AidanPark**: Solo la lógica de API o de conexión.

---

## 🛡️ Recertificación Post-Actualización

Tras cada fusión desde el upstream, **debes** ejecutar nuestro protocolo de salvación para asegurar que el ADN de Android no se ha roto:

```bash
# 🟢 1. Fix de entorno y variables
oa fix-env

# 🟢 2. Ejecutar diagnóstico de salud
oa doctor

# 🟢 3. Re-aplicar parches de hardware
oa fix-android
```

---

| Elemento | Riesgo | Acción |
| :--- | :--- | :--- |
| **Parch GLIBC DNS** | Alto (DNS error) | Usar nuestra versión **Híbrida** de la v1.1.3. |
| **Rutas /bin/sh** | Alto (Shebang error) | Mantener nuestro shim de `/data/data/.../sh`. |
| **Modo Ultra-Lote** | Medio (OOM Error) | Asegurar que `oa start` siga inyectando el flag `--max-old-space-size`. |

---
**Recuerda:** En este fork, el código es **tuyo**. La ligereza es nuestra mayor virtud. ¡Sigamos adelante! 🚀
