# 📱 Case Study: Deploying OpenClaw on Motorola Moto G6 (Legacy 32-bit)

This document serves as a real-world example and guide for users attempting to run **OpenClaw** on legacy Android hardware with limited resources (32-bit architecture, low RAM).

## 🚀 Credits & Attribution

- **OpenClaw (Android Gateway):** Based on the core platform at [openclaw/openclaw](https://github.com/openclaw/openclaw).
- **OmniBrain-AI-Proxy-Smart (Smart Proxy):** Originally a demo by `midudev`, it was **comprehensively refactored and optimized for production** by the author ([ANONIMO432HZ](https://github.com/ANONIMO432HZ/OmniBrain-AI-Proxy-Smart)) to enable low-latency routing and high-availability on mobile devices.

---

## 🔍 Device Profile

- **Model:** Motorola Moto G6 (XT1925) "Alium".
- **CPU:** Qualcomm Snapdragon 450 (Octa-core 1.8 GHz).
- **RAM:** 2GB (Critical constraint).
- **Architecture:** `armv7l` (32-bit).
- **Android Version:** 9 (Stock).

---

## 🛠️ The Challenge

Most modern AI agent platforms assume a 64-bit environment (`aarch64`) and at least 4GB of RAM. On a 32-bit device with 2GB RAM, several issues arise:

1. **Binary Compatibility:** Official `aarch64` binaries (like Bun or standard Node-Glibc) will not execute.
2. **Resource Exhaustion:** Background processes (like `code-server` or `Chromium`) can freeze the device or lead to OOM (Out Of Memory) kills.
3. **Database Failures:** High-performance SQLite wrappers like `better-sqlite3` often fail to compile on older 32-bit Android kernels.

---

## ✅ Successful Strategy (Bypass & Optimization)

### 1. Native "Lite" Environment

Instead of using `proot-distro` (which adds ~700MB overhead and an emulation layer), we used **Native Termux mode**.

- **Node.js:** Installed via `pkg install nodejs-lts` (32-bit native).
- **Persistence:** Switched to `sql.js` (WASM) for the database to bypass native compilation failures.

### 2. External AI Proxy (OmniBrain-AI-Proxy-Smart)

To keep the phone's CPU and RAM usage low, we integrated [OmniBrain-AI-Proxy-Smart](https://github.com/ANONIMO432HZ/OmniBrain-AI-Proxy-Smart) as a universal proxy.

- **Benefit:** The logic for selecting models (Groq, OpenRouter, Cerebras) and handling fallbacks happens on the proxy, not the phone.
- **Result:** Zero latency penalty and significantly lower power consumption.

### 3. SSH Tunneling for Dashboard Access

Since the Moto G6 is purely a gateway, the UI (Dashboard) is accessed from a remote PC.

- **Problem:** "Origin Not Allowed" errors when accessing via IP.
- **Solution:** Mapping port 18789 via SSH tunnel:

  ```bash
  ssh -p 8022 -L 18789:127.0.0.1:18789 u0_aXXX@IP_PHONE
  ```

---

## 🚀 Step-by-Step Achievement

### Phase A: Environment Preparation

1. Installed Termux from **F-Droid**.
2. Disabled Android's battery optimizations and the "Phantom Process Killer" (critical for Android 12+, though not on this specific Moto G6).
3. **Ejecutar:**

    ```bash
    pkg update && pkg install nodejs-lts git openssh tmux
    ```

### Phase B: Integration

1. Ran the installer from `ANONIMO432HZ/openclaw-android-multiarch`.
2. Selected ONLY the **Gateway** and **CLI** components. Avoided `code-server` and `OpenCode`.
3. Configured the API Endpoint to point to a local instance of **OmniBrain-AI-Proxy-Smart** running on the network.

### Phase D: OpenClaw Onboarding (Smart Hub Integration)

To enable the **Smart Routing** features of OmniBrain-AI-Proxy-Smart, follow these steps during the OpenClaw initial setup (Onboarding):

1. **Choose Provider:** Select **"Custom"** or **"OpenAI Compatible"**.
2. **Base URL:** Enter your proxy address (e.g., `http://192.168.0.100:3000/v1`).
3. **API Key:** Any string (the proxy validates routing, but OpenClaw requires a placeholder).
4. **Model ID:** Explicitly set this to **`auto`**.
   - *Why?* This tells OmniBrain-AI-Proxy-Smart to use its internal intelligence to route your request to the fastest available provider (Groq/Cerebras) and handle fallbacks automatically without overloading the phone's CPU.

### Phase C: Execution

1. Started the gateway in a `tmux` session to ensure persistence:

    ```bash
    tmux new -s openclaw
    node --max-old-space-size=512 $(which openclaw) gateway run
    ```

2. Connected from PC via SSH tunnel and verified the dashboard at `http://localhost:18789`.

---

## 📈 Results

- **Idle RAM usage:** 150MB.
- **CPU temperature:** ~45°C (Stable during normal operation).
- **Latency:** <50ms (Proxy routing).

**Conclusion:** Legacy devices can serve as excellent, dedicated "AI Gateways" provided you offload heavy computation and avoid emulation layers.
