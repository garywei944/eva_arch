#!/usr/bin/env zsh

# Pixi workspace shortcuts. Keep the `px` prefix predictable:
# core commands use `px<verb>`, tasks use `pxt*`, globals use `pxg*`,
# and workspace-platform commands use `pxwp*`.

# Core workspace lifecycle
alias px='pixi'
alias pxi='pixi init'
alias pxa='pixi add'
alias pxap='pixi add --pypi'
alias pxrm='pixi remove'
alias pxin='pixi install'
alias pxu='pixi update'
alias pxup='pixi upgrade'
alias pxl='pixi list'
alias pxt='pixi tree'
alias pxr='pixi run'
alias pxs='pixi shell'
alias pxx='pixi exec'
alias pxinfo='pixi info'
alias pxcl='pixi clean'

# Tasks
alias pxta='pixi task add'
alias pxtrm='pixi task remove'
alias pxtl='pixi task list'

# Global tools
alias pxg='pixi global'
alias pxgi='pixi global install'
alias pxgun='pixi global uninstall'
alias pxga='pixi global add'
alias pxgrm='pixi global remove'
alias pxgl='pixi global list'
alias pxgs='pixi global sync'
alias pxgu='pixi global update'
alias pxgt='pixi global tree'
alias pxge='pixi global edit'

# Workspace platforms and virtual packages
alias pxwp='pixi workspace platform'
alias pxwpa='pixi workspace platform add'
alias pxwpe='pixi workspace platform edit'
alias pxwpl='pixi workspace platform list'
alias pxwpr='pixi workspace platform remove'
