# 📚 Nix-Config Docs

Documentation for the `nix-config` repo — **read directly on GitHub**.

Each page answers one practical question; read by need, no particular order.

## Where to start

| Page | Contents |
|---|---|
| **[03 — Fresh install from scratch](03-Cai-May-Moi.md)** | USB → partitioning → `nixos-install` → hibernate check → **Step 10: Git & SSH** |
| **[06 — VM practice](06-Luyen-Tap-VM.md)** | Practice installing with a virtual machine (QEMU/KVM), zero risk |

## Quick flows by situation

- **New machine** → [03](03-Cai-May-Moi.md)
- **Practice installing first** → [06](06-Luyen-Tap-VM.md)
- **New system checklist**: set a password ([03 Step 7.5](03-Cai-May-Moi.md)) and SSH key on GitHub ([03 Step 10](03-Cai-May-Moi.md))

## Most important takeaway

- Changes only take effect after `sudo nixos-rebuild switch --flake .#laptop` (or `nh os switch`).
- **Config** lives in Nix → reproducible from the repo. **Data** (API keys, documents…) lives outside Nix → remember to back it up.