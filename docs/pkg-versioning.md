#Pkg versioning
[Snapshot packages](https://fedoraproject.org/wiki/Packaging:NamingGuidelines#Snapshot_packages) contain data about where the snapshot came from as well as ordering information for rpm. The information about the snapshot will be called %{checkout} in this section.

%{checkout} consists of the date that the snapshot is made in YYYYMMDD format, a short (2-5 characters) string identifying the type of revision control system or that this is a snapshot, and optionally, up to 13 characters (ASCII) alphanumeric characters that could be useful in finding the revision in the revision control system.

For instance, if you create a snapshot from a git repository on January 2, 2011 with git hash 9e88d7e9efb1bcd5b41a408037bb7cfd47220a64, %{checkout} string could be any of the following:

```
20110102snap
20110102git
20110102git9e88d7e
```

If the snapshot package is considered a "pre-release package", follow the guidelines listed in Pre-Release Packages for snapshot packages, using the %{checkout} that you decide on above. (For instance, in kismet-0-0.3.20040204svn, 20040204svn is the %{checkout})

If the snapshot is a "post-release package", follow the guidelines in the Post-Release Packages section. Where the %{posttag} in that section is the %{checkout} string you decided on above.

Example (post-release cvs):
```
kismet-1.0-1%{?dist} (this is the formal release of kismet 1.0)
kismet-1.0-2%{?dist} (this is a bugfix build to the 1.0 release)
kismet-1.0-3.20050515cvs%{?dist} (move to a post-release cvs checkout)
kismet-1.0-4.20050515cvs%{?dist} (bugfix to the post-release cvs checkout)
kismet-1.0-5.20050517cvs%{?dist} (new cvs checkout, note the increment of %{X})
```

***

##  Base release off latest release tag

```
# clone and checkout desired commit
git clone -b "$branch" "$git_url" "${git_dir}"
cd "${git_dir}"

# get latest base release
# This is used because upstream does tends to use release tags
release_tag=$(git describe --abbrev=0 --tags)
git checkout $release_tag 1> /dev/null

# cleanup for pkg version naming
pkgver=$(sed "s|[-|a-z]||g" <<<"$release_tag")

# Alter pkg suffix based on commit
pkgsuffix="git+bsos${pkgrev}"
```

##  Base release off latest commit (for "unstable packages")

```
# clone and checkout desired commit
git clone -b "$branch "$git_url" "${git_dir}"
cd "${git_dir}"
latest_commit=$(git log -n 1 --pretty=format:"%h")
git checkout $latest_commit 1> /dev/null

# get latest base release for changelog 
# This is used because upstream does tend to use release tags
pkgver_orig=$(git tag | tail -n 1)
pkgver=$(sed "s|[-|a-z]||g" <<<"$pkgver_orig")

# Alter pkg suffix based on commit
pkgsuffix="${latest_commit}git+bsos${pkgrev}"
```
