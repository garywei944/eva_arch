# conda plugin

The conda plugin provides [aliases](#aliases) to `conda`, usually it's
installed by [anaconda](https://www.anaconda.com/)
or [miniconda](https://docs.conda.io/en/latest/miniconda.html).

To use it, add `conda` to the plugins array in your zshrc file:

```zsh
plugins=(... conda)
```

## Aliases

| Alias  | Command                                     |
|:-------|:--------------------------------------------|
| ca     | conda activate                              |
| cde    | conda deactivate                            |
| cel    | conda env list                              |
| clst   | conda list                                  |
| cle    | conda list --export                         |
| cles   | conda list --export > spec-file.txt         |
| cee    | conda env export                            |
| ceee   | conda env export > environment-spec.yml     |
| conin  | conda install                               |
| coniny | conda install -y                            |
| crn    | conda remove -y --all -n                    |
| ccn    | conda create -y -n                          |
| ccf    | conda env create -f                         |
| ccfe   | conda env create -f environment.yml         |
| cconf  | conda config                                |
| ccss   | conda config --show-source                  |
| cuf    | conda env update -f                         |
| cufe   | conda env update -f environment.yml         |
| cufep  | conda env update -f environment.yml --prune |
| cufp   | conda env update --prune -f                 |

## `mamba` support

All alias except `ca` and `cde` have a `mamba` version of it which replace the
initial `cxxx` with `mxxx`, or `conxx` to `mamxx`. e.g.,

* `ccfe` -> `mcfe`
* `conin` -> `mamin`

## No known Conflicts!

Perform the following commands to check conflicts,

```bash
for alias in $(rg -N '^alias' conda.plugin.zsh | sed 's/^alias //g;s/=.*$//g'); do # Check each alias in `conda` plugin
        rg '[^-:\.%<]\b'"$alias"'\b[^-]' ~/.oh-my-zsh/plugins
done
```

Nothing it conflicts with!

---

*Updated March 21, 2023*
