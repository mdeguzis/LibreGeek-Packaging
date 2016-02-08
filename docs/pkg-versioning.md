#Pkg versioning
***

##  Clone and checkout desired commit

```
git clone -b "$rel_target" "$git_url" "${git_dir}"
cd "${git_dir}"
latest_commit=$(git log -n 1 --pretty=format:"%h")
git checkout $latest_commit 1> /dev/null
```

## Get latest base release for changelog
If no base release tag exists, try to search the code. If there is absolutely no trace of a version, use a short-data format. Some projects do not update release tags. In this case, if a version is not foudn in the code, use your best judgement.

```
pkgver_orig=$(git tag | tail -n 1)
pkgver=$(sed -ie "|[-|a-z]||g")
```

## Alter pkg suffix based on commit
pkgsuffix="git${latest_commit}+bsos${pkgrev}"
