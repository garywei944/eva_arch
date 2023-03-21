#!/usr/bin/env zsh

ZSH_CUSTOM=${0:a:h:h}  # ../.. of this script

check_alias(){
  for alias in $(rg -N '^alias' $1 | sed 's/^alias //g;s/=.*$//g'); do
    [[ $alias =~ 'c|t|s' ]] && continue
    rg '[^-:\.%<]\b'"$alias"'\b[^-]' ~/.oh-my-zsh/plugins
  done
}

# Test for all alias
for file in $ZSH_CUSTOM/*.zsh; do
  check_alias $file
done

# Test for all plugins
for file in $ZSH_CUSTOM/plugins/**/*.plugin.zsh; do
  check_alias $file
done