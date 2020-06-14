The following describes the current status of building and booting a
NixOS image for MAAS. Building works but booting the image results in
the error described below:

1. Build the image as follows:
```
imgdir=$(nix-build test-maas-img.nix --no-link)
```

2. Upload it to a MAAS server you have SSH access to:
```
scp $imgdir/nixos-20.09pre-git-x86_64-linux.tgz  me@maas:/home/me/nixos-20.09pre-git-x86_64-linux.tgz
```

3. Login to maas via the CLI:
```
maas login me http://maas:5240/MAAS/api/2.0
```

4. Upload the image to MAAS:
```
maas me boot-resources create \
  name=nixos \
  title=”NixOS” \
  architecture=amd64/generic \
  content@=/home/me/nixos-20.09pre-git-x86_64-linux.tgz
```

5. Deploy a machine with the custom "NixOS" image.

6. Observe in the machine log that the installation failed with the
   following error:

```
...
2020-06-14 15:55:05 (41.2 MB/s) - written to stdout [640661039/640661039]

finish: cmd-install/stage-extract/builtin/cmd-extract: SUCCESS: acquiring and extracting image from http://maas:5248/images/custom/amd64/generic/nixos/uploaded/root-tgz
Applying write_files from config.
finish: cmd-install/stage-extract/builtin/cmd-extract: SUCCESS: curtin command extract
start: cmd-install/stage-curthooks/builtin/cmd-curthooks: curtin command curthooks
Running curtin builtin curthooks
finish: cmd-install/stage-curthooks/builtin/cmd-curthooks: FAIL: curtin command curthooks
Traceback (most recent call last):
  File "/curtin/curtin/commands/main.py", line 202, in main
    ret = args.func(args)
  File "/curtin/curtin/commands/curthooks.py", line 1619, in curthooks
    builtin_curthooks(cfg, target, state)
  File "/curtin/curtin/commands/curthooks.py", line 1423, in builtin_curthooks
    distro_info = distro.get_distroinfo(target=target)
  File "/curtin/curtin/distro.py", line 117, in get_distroinfo
    variant_name = os_release(target=target)['ID']
KeyError: 'ID'
'ID'
```

   So in the `get_distroinfo` function `curtin`
   [calls](https://github.com/canonical/curtin/blob/7310b4fe614651640aecfe1cea67a0a5a1594224/curtin/distro.py#L117)
   the `os_release` function (defined a few lines above it) which
   reads the `/etc/os-release` file and returns all key value pairs
   as a dictionary. Then it extracts the `ID` key out of that
   dictionary which apparentely doesn't exist.

   The latter is surprising because NixOS
   [sets up](https://github.com/NixOS/nixpkgs/blob/47a18b58b2f5c81e0d59e3a2b91d4a9c744870d2/nixos/modules/misc/version.nix#L105)
   `/etc/os-release` to contain an `ID` field (mapping to `NixOS`).
