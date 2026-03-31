# 🚀 Mantenimiento de Upstream: OpenClaw Termux Edition

Esta guía técnica detalla el procedimiento para sincronizar este fork con las actualizaciones del motor original de **AidanPark/openclaw-android**, garantizando que la arquitectura **V3 (Termux-Only)** permanezca intacta, ligera y funcional.

---

## 🎯 Filosofía de este Fork
Este repositorio es una **edición exclusiva para Termux**. Hemos eliminado quirúrgicamente:
- 🗑️ Carpeta `android/` (Código Java/Kotlin/UI del APK).
- 🗑️ `.github/workflows/` (Flujos de compilación de binarios Android).
- 🗑️ Dependencias de desarrollo web pesadas exclusivas del frontend.

**REGLA DE ORO:** Al actualizar desde el upstream, solo nos interesan los cambios en `scripts/`, lógica del core y dependencias críticas del motor. **Cualquier intento de Git por reintroducir la carpeta `android/` debe ser abortado o revertido.**

---

## 🛠️ Configuración del Entorno de Fusión

Si aún no has configurado el origen remoto (solo se hace una vez):

```bash
git remote add upstream https://github.com/AidanPark/openclaw-android.git
git fetch upstream
```

Para verificar tu configuración: `git remote -v`. Deberías ver tanto `origin` como `upstream`.

---

## 🔄 El Flujo de Trabajo Profesional (Sync)

Sigue estos pasos rigurosamente para evitar "corromper" la ligereza de la Termux Edition:

### 1. Preparación y Captura
```bash
git checkout main
git pull origin main
git fetch upstream
```

### 2. Intento de Fusión (Merge)
```bash
git merge upstream/main --no-commit
```
*Usamos `--no-commit` para revisar qué archivos quiere añadir Git antes de que se integren.*

### 3. Limpieza de "Peso Muerto" Post-Merge
Si el merge intentó revivir archivos del APK:
```bash
# Si aparecieron estas carpetas, bórralas de nuevo
rm -rf android/
rm -rf .github/workflows/

# Marca las eliminaciones para el commit
git add .
```

### 4. Resolución de Conflictos Estructurales
Si hay conflictos en `scripts/lib.sh` o `oa.sh`, **SIEMPRE PRIORIZA** nuestras rutas de Termux y constantes de color. Nuestras versiones están optimizadas para la memoria limitada de Android.

---

### 5. Re-Certificación de Estabilidad 🛡️

Una vez finalizado el merge, es obligatorio re-ejecutar el motor de diagnóstico para asegurar que nada se rompió:

```bash
# 1. Autocura el entorno tras los cambios de código
oa fix-env

# 2. Re-aplica parches de compatibilidad (Sharp/Chromium)
oa update

# 3. Lanza el diagnóstico completo
oa doctor
```

---

## 🔍 Matriz de Mantenimiento

| Escenario | Acción Recomendada |
| :--- | :--- |
| **El upstream cambió dependencias** | Revisa `package.json`. Si añadieron librerías nativas, ejecutas `oa update` para intentar el build en el dispositivo. |
| **El upstream cambió la lógica del core** | Fusión directa. Es lo que más nos interesa. |
| **El upstream añadió nuevas funciones UI** | **IGNORAR**. Nosotros no usamos la interfaz gráfica del APK. |
| **El merge causó errores de GLIBC** | Ejecuta `oa doctor`. Probablemente necesites re-vincular las librerías con `oa fix-android`. |

---

## 💡 Consejo de Pro
Si un commit del upstream rompe la compatibilidad con 32 bits (ARMv7), no lo fusiones. Nuestra prioridad es la **inclusividad de hardware**. Si tienes dudas, puedes abortar cualquier proceso con:
`git merge --abort`

**Mantén el código limpio. Mantén el código ligero.** 🚀
