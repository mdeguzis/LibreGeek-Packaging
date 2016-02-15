# Tips and Tricks

## Pass results of find to command

```
find . -name "SEARCHSTRING" -print0 | xargs -0 COMMAND
```

## Replace line with contents of file

```
perl -pe 's/install_prereqs/`cat temp`/e'
```

## Replace line with block of text in file (perl)

```
# Test
perl -pe 's|OLD|`cat blockoftext`|e' 

# Replace in-place (e.g. sed -i)
perl -pe 's|OLD|`cat blockoftext`|e' -i
```
