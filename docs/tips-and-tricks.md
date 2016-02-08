#Pkg versioning
***

##  clone and checkout desired commit

```
git clone -b "$rel_target" "$git_url" "${git_dir}"
cd "${git_dir}"
latest_commit=$(git log -n 1 --pretty=format:"%h")
git checkout $latest_commit 1> /dev/null
```

## get latest base release for changelog

```
pkgver_orig=$(git tag | tail -n 1)
pkgver=$(sed -ie "|[-|a-z]||g")
```

## Alter pkg suffix based on commit
pkgsuffix="git${latest_commit}+bsos${pkgrev}"
