# linux-wallpaperengine local package

Pinned rebuild of upstream `b016d7d1` used by `wallpaper-engine-control`.

- `0001-*`: contain the ScriptEngine album-art callback use-after-free.
- `0002-*`: `SIGUSR1` makes every active playlist advance one wallpaper
  (`wallpaper-engine-control next`).

Build somewhere outside the dotfiles worktree:

    cp -r ~/.config/linux-wallpaperengine-pkg ~/sandbox/lwe-build
    cd ~/sandbox/lwe-build && makepkg -si
