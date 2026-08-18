# Pixi plugin

Personal Oh My Zsh aliases for Pixi. Every alias uses the `px` prefix so it is
predictable and does not overlap with the existing Conda (`cn`), Mamba (`m`),
or micromamba (`mm`) shortcuts.

## Core workspace commands

| Alias | Command |
|---|---|
| `px` | `pixi` |
| `pxi` | `pixi init` |
| `pxa` | `pixi add` |
| `pxap` | `pixi add --pypi` |
| `pxrm` | `pixi remove` |
| `pxin` | `pixi install` |
| `pxu` | `pixi update` |
| `pxup` | `pixi upgrade` |
| `pxl` | `pixi list` |
| `pxt` | `pixi tree` |
| `pxr` | `pixi run` |
| `pxs` | `pixi shell` |
| `pxx` | `pixi exec` |
| `pxinfo` | `pixi info` |
| `pxcl` | `pixi clean` |

## Tasks

| Alias | Command |
|---|---|
| `pxta` | `pixi task add` |
| `pxtrm` | `pixi task remove` |
| `pxtl` | `pixi task list` |

## Global tools

| Alias | Command |
|---|---|
| `pxg` | `pixi global` |
| `pxgi` | `pixi global install` |
| `pxgun` | `pixi global uninstall` |
| `pxga` | `pixi global add` |
| `pxgrm` | `pixi global remove` |
| `pxgl` | `pixi global list` |
| `pxgs` | `pixi global sync` |
| `pxgu` | `pixi global update` |
| `pxgt` | `pixi global tree` |
| `pxge` | `pixi global edit` |

## Workspace platforms

| Alias | Command |
|---|---|
| `pxwp` | `pixi workspace platform` |
| `pxwpa` | `pixi workspace platform add` |
| `pxwpe` | `pixi workspace platform edit` |
| `pxwpl` | `pixi workspace platform list` |
| `pxwpr` | `pixi workspace platform remove` |

## CUDA PyTorch example

Starting from a new workspace on Linux:

```zsh
pxi --channel conda-forge
pxwpe linux-64 --cuda 13.0
pxa "python=3.14.*" "cuda-version=13.0.*" "pytorch-gpu=*=cuda130*"
pxr python -c 'import torch; print(torch.__version__, torch.version.cuda, torch.cuda.is_available())'
```

Use quotes around MatchSpecs containing `*` so Zsh does not expand them as
filename globs.
