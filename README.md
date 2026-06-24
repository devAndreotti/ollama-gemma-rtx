# ollama-gemma-rtx

Pre-tuned Ollama Modelfiles for running Google Gemma models on laptop GPUs (RTX 2050 / 4 GB VRAM). Drop-in configs that unlock full CUDA offload where Ollama's auto-estimator is too conservative.

> **Tested on:** Windows 11 · NVIDIA RTX 2050 4 GB (Optimus/hybrid) · 16 GB RAM · Ollama ≥ 0.30.x

---

## Results at a glance

| Model | Ollama tag | Speed | VRAM | Context | GPU layers |
|---|---|---|---|---|---|
| **Gemma 4 E2B QAT** | `gemma4-cuda` | ~49 tok/s | 1.6 GB | **128K** | 36/36 (100%) |
| **Gemma 4 E4B QAT** | `gemma4e4b-cuda` | ~29 tok/s | 3.0 GB | 32K | 43/43 (100%) |
| Gemma 2 9B q3_K_S | `gemma9-cuda` | ~7.7 tok/s | 4.0 GB | 8K | 33/43 (70%) |

**Recommendation:**
- Daily driver → **E4B** (better quality, still fast, fits entirely on GPU)
- Long documents / speed bursts → **E2B** (49 tok/s, 128K context)
- Gemma 2 9B is outclassed by the E4B on every metric and only included for reference

---

## Why this exists

Ollama's automatic GPU-layer estimator is too conservative on Optimus (hybrid) laptops. On this machine, out of the box it:
- Picked the **Vulkan backend** (pathologically slow: ~4 tok/s)
- Offloaded only **13 of 36 layers** to the GPU

With the right `num_gpu` override and `OLLAMA_VULKAN=0`, the same hardware runs **~49 tok/s at 100% GPU**.

These Modelfiles encode that discovery so you don't have to repeat it.

---

## Prerequisites

1. **Ollama ≥ 0.30.x** — earlier versions don't support Gemma 4
   ```
   winget install --id Ollama.Ollama --silent --accept-package-agreements
   ```

2. **Force CUDA** (one-time, survives reboots):
   ```bat
   setx OLLAMA_VULKAN 0
   ```
   Then restart the Ollama app. Vulkan is consistently 10–12× slower than CUDA on Optimus GPUs.

3. **Pull the base models** (downloads happen once; blobs are shared):
   ```
   ollama pull gemma4:e2b-it-qat     # ~1.6 GB
   ollama pull gemma4:e4b-it-qat     # ~6.1 GB on disk (only 3.0 GB loaded in VRAM)
   ollama pull gemma2:9b-instruct-q3_K_S  # ~4.3 GB  (optional)
   ```

---

## Setup

Create the derived models (no extra disk space — just manifests pointing to existing blobs):

```bat
ollama create gemma4-cuda    -f modelfiles\gemma4-2b.Modelfile
ollama create gemma4e4b-cuda -f modelfiles\gemma4-e4b.Modelfile
ollama create gemma9-cuda    -f modelfiles\gemma2-9b.Modelfile
```

Run:
```bat
ollama run gemma4-cuda       :: fast, huge context
ollama run gemma4e4b-cuda    :: smarter
```

Or use the `.bat` launchers in `launchers/` — double-click to start Ollama + open a chat in one step.

---

## Architecture notes (why these numbers work)

### Gemma 4 — PLE / MatFormer architecture
The E4B weighs **6.1 GB on disk** but only uses **3.0 GB of VRAM** at 100% GPU offload. This is because of **Per-Layer Embeddings (PLE)**: embedding lookups are handled CPU-side cheaply (they're just table lookups, not matrix multiplications), while the actual compute layers go fully to the GPU. The result is a much smaller runtime VRAM footprint than the file size suggests.

### Gemma 4 — Sliding-window attention & KV cache
Only 3 of ~15 attention layers use full context; the rest use a small sliding window. This keeps the **KV cache tiny even at 128K context** (~1.7 GB). KV cache quantization (q8_0/q4_0) and Flash Attention were tested and provided no benefit here — they saved ~50–150 MB at a slight speed cost.

### Gemma 2 9B — VRAM cliff
With the 9B, **more GPU layers ≠ faster**. At ≥ 36 layers CUDA spills into shared memory (Optimus unified memory) and becomes *slower* than at 33 layers, even while `ollama ps` shows "100% GPU". The sweet spot is **33 layers**. Setting `num_gpu 99` here would be counterproductive.

---

## Windows power plan (measured: +31% on CPU-offloaded models)

Laptops often ship on the **Power saver** plan, which throttles the CPU. This barely affects fully-GPU-resident models (the GPU boosts on its own under load), but it heavily penalizes any model that offloads layers to the CPU.

Measured on this machine, switching from **Power saver** to **Ultimate Performance**:

| Model | Power saver | Ultimate Performance | Δ |
|---|---|---|---|
| Gemma 4 E4B (100% GPU) | 29 tok/s | 28 tok/s | ~none |
| Gemma 2 9B (30% CPU) | 7.7 tok/s | **10.1 tok/s** | **+31%** |

Enable it (the plan may need to be created first on some installs):
```bat
powercfg /setactive 98c56a02-4c00-471e-9432-7211b6a01f73   :: Ultimate Performance
:: if that GUID doesn't exist:  powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
```

**Battery note:** Ultimate Performance drains the battery if left unmanaged. Rather than auto-swapping plans (fragile on Windows — WMIC is removed and power-source event triggers are unreliable), tune the plan's **DC (battery) profile** to be conservative while keeping AC at full performance. Windows applies these automatically based on power source:
```bat
:: Battery: let the CPU idle and trim turbo; AC: full blast
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 5
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 90
powercfg /setacvalueindex SCHEME_CURRENT SUB_PCIEXPRESS  ASPM 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PCIEXPRESS  ASPM 2
powercfg /setactive SCHEME_CURRENT
```

---

## What we tested that didn't help

- **`num_batch 1024`** (vs default 512): no prefill gain on these small models — run-to-run variance (1615–1836 tok/s) exceeded any effect, and it cost +0.3 GB VRAM. The "+60% throughput" figures floating around are for large models on big GPUs, not a 2B on 4 GB.
- **KV cache quantization (q8_0/q4_0)** and **Flash Attention**: no benefit on Gemma 4 — sliding-window attention already keeps the KV cache tiny (~1.7 GB at 128K). Slightly slower, saved ~50–150 MB.
- **TurboQuant KV compression**: the upstream llama.cpp PR was rejected; it's CPU-only and forks are experimental. Not viable.

---

## Gotchas

**`nvidia-smi` is unreliable on Optimus laptops.**
It reports ~750 MiB regardless of actual load. Use `ollama ps` or watch the llama.cpp logs (`offloaded X/Y layers`, `KV buffer size`) instead.

**Kill `llama-server.exe` between restarts, not just `ollama.exe`.**
Ollama's `keep_alive` keeps the runner process alive. If you restart the app without killing the runner, it holds VRAM → fake "CUDA out of memory" errors and `0xc0000409` stack overflow crashes on the next load.
```bat
taskkill /F /IM llama-server.exe
```

**Gemma 4 needs Ollama ≥ 0.30.x.**
Earlier versions return `412: requires a newer version`. Update via winget (see Prerequisites).

**E4B needs ~5 GB of free RAM to load.**
The model uses mmap for staging even though it runs 100% on GPU. If you're low on RAM, close other apps before loading.

**Gemma 2 9B context is hard-capped at 8192 tokens.**
Requesting a larger context has no effect — llama.cpp clamps it internally. This is a model-level limit, not an Ollama setting.

---

## Tuning `num_gpu` for your GPU

These values were found by sweeping manually. The process:

1. Start with `num_gpu 99` (try to offload everything)
2. Check `ollama ps` — if `PROCESSOR` shows `100% GPU` and speed is good, done
3. If you get OOM, lower `num_gpu` by ~5 and repeat
4. Watch the llama.cpp log: `offloaded X/Y layers` tells you the actual split
5. For hybrid/Optimus GPUs: test a few values around the optimum — there may be a "cliff" where adding layers suddenly makes things slower (Gemma 2 9B hits this at layer 36)

To find the log:
```bat
ollama serve 2>&1 | findstr /i "offload\|layer\|KV"
```

---

## In-chat tips

```
/set nothink    disable reasoning mode for faster responses
/bye            exit the chat
```

Check loaded model and GPU usage:
```bat
ollama ps
```

---

## License

These are configuration files only. No model weights are included or redistributed.

The underlying models are subject to Google's [Gemma Terms of Use](https://ai.google.dev/gemma/terms). By pulling and using them via Ollama, you agree to those terms.

This repo itself is MIT licensed.
