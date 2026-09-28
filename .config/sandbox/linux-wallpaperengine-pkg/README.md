# linux-wallpaperengine local package

Pinned rebuild of upstream `b016d7d1`.

- `0001-*`: contain the ScriptEngine album-art callback use-after-free.

`wallpaper-engine-control` needs no renderer patch: it switches wallpapers by
relaunching a renderer with `--bg`, so a stock upstream build works as well.

Build somewhere outside the dotfiles worktree:

    cp -r ~/.config/sandbox/linux-wallpaperengine-pkg ~/sandbox/lwe-build
    cd ~/sandbox/lwe-build && makepkg -si
