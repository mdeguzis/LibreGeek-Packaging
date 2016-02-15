# Git

Revert a commit:
```
git revert --no-commit 0766c053..HEAD
git commit
```

# Other notes
* Some folders here may be a [sub-module](https://git-scm.com/book/en/v2/Git-Tools-Submodules). If you clone this repository, ensure you add the --recursive option flag. You can also use

```
git pull --recurse-submodules
git submodule update --recursive
```
