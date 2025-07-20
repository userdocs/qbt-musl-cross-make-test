# `Makefile`

`ADDED:` a new `download_only` target that will bootstrap all archive type dependencies to `sources`

`ADDED:` gcc snapshot urls to build against gcc snapshot versions using `GCC_VER = 16-20250720` for example.

`ADDED:` musl snapshot to use commit snapshots archive instead of cloning the git repo - to do this use the full commit sha. Maybe there is a way to use shortened sha versions like with `git-12345678` but this works for what we need here.
```
MUSL_VER = 8fd5d031876345e42ae3d11cc07b962f8625bc3b
```

`CHANGED:` download command to curl.

`CHANGED:` move urls to `source_urls.mak` and included it in the `Makefile`

`CHANGED:` split `versions.mak` and `config.mak` into separate files because we don't need most config.mak into that is sourced into Makefile. 
`versions.mak` is sourced into Makefile and `config.mak` is sourced into `litecross/Makefile`

`CHANGED:` `SOURCES = $(shell pwd)/sources` add full path to working directory. Fixed an issue with the process getting confused about where it was when downloading dependencies.

> [!NOTE] 
> These changes directly translate to efficient CI bootstrapping and allow for using a dependency cache via `actions/cache`  to only download when dependencies are changed.
>
> Not so advanced as to account for each dependency individually but enough to only trigger if the [versions.mak](versions.mak) is changed. As this file is now separated from the [config.mak](config.mak) and Makefile [Makefile](Makefile) it should be enough to minimise downloads.
>
> With minimal changes to [Makefile](Makefile)

# `litecross/Makefile`

`CHANGED:` Move target logic out of this file and into the `config.mak` so it is transparent to user. If not in the [config.mak](config.mak) or [triples.json](triples.json) it is not applied.

`CHANGED:` gcc and binutils build sections are harmonized and order of variables changed to reflect how a user might assume they would be when using the `config.mak`

```
FULL_BINUTILS_CONFIG = --prefix= --libdir=/lib --target=$(TARGET) --with-sysroot=$(SYSROOT) \
	$(COMMON_CONFIG) \
	$(BINUTILS_CONFIG)

FULL_GCC_CONFIG = --prefix= --libdir=/lib --target=$(TARGET) --with-sysroot=$(SYSROOT) \
	$(COMMON_CONFIG) \
	$(GCC_CONFIG) \
	$(GCC_CONFIG_FOR_TARGET)
```

So in the [config.mak](config.mak) we can set the `COMMON_CONFIG` for shared options and `GCC_CONFIG_FOR_TARGET` is set via the [triples.json](triples.json) settings

# `Project`

`CHANGED:` Removed `sources` from gitignore and added `config.sub` to it. BIt won't be downloaded that was and no need to edit Makefile logic to work around this.

`ADDED:` `builder-helper.bash` file to easily build selected triples from `triple.json` locally via docker.

It will prompt you through selection of a target and how to build it via the [triples.json](triples.json)

```bash
./builder-helper.bash
./builder-helper.bash target
./builder-helper.bash target build
```

# `CI`

This ci is build around the idea that a person will have their target and arch config listed in the `triples.json` file and a [config.mak](config.mak) focused on the general build configuration.

Most changes above are part of creating a streamlined and easy to use ci workflow.

```
ci-main-reusable-caller.yml             # parent that creates the matrix jobs and from triples.json
└── ci-bootstrap-build-deps.yml         # downloads and caches the dependencies if needed or skipped
    └── ci-mcm-build.yml                # Builds mcm to the config.mak and versions.mak settings
        └── ci-mcm-release.yml          # Release the toolchains as release assets to a latest release
            └── ci-docker-build.yml     # Build the dockers images using the Dockerfile
                └── ci-docker-test.yml  # Test docker images to build a hello world static linked to zlib
```

inputs available to `workflow_dispatch` are:

- `branch` - choose branch to run from
- `GNU mirror` url - For example teh [Makefile](Makefile)defaults to https://mirrors.dotsrc.org/gnu whilst the CI defaulting to using https://mirrors.dotsrc.org/gnu
- `arm64` matrix only - only build on `ubuntu-24.04-arm` runners
- `amd64` matrix only - only build on `ubuntu-24.04` runners
- `arm64` and `amd64` matrix  build on `ubuntu-24.04-arm` and `ubuntu-24.04` runners
- only build toolchains (skip docker jobs) - Will skip docker jobs and run toolchain build only
- only run docker jobs (requires published release from `ci-mcm-build.yml` into `ci-mcm-release.yml`) - only run the docker related jobs. To rebuild when updating Dockerfile but not toolchain.

> [!NOTE] 
> Caching and the Makefile (or make in general?) have a peculiar problem. When caching the dependencies the last modified attributes would be set before that of the `hashes/*.sha1` files from `actions/checkout`. 
> This caused the download to be run because the `make` does a hash check and decides that because the archive is older than the sha file it should force the download to happen again. This was resolved using this method.
>
>   ```
>   - name: Host - Cache sources (restore)
>        uses: actions/cache/restore@v4
>        with:
>        path: ${{ github.workspace }}/sources
>        key: mcm-sources-${{ hashFiles('versions.mak') }}
>
>    - name: Host - Github cache files - update timestamps
>        run: find ${{ github.workspace }}/sources/ -type f -exec touch -a -m {} +
>    ```
>
> This issue did not occur if I downloaded deps and used `actions/upload-artifact`/`actions/download-artifact` instead oc caching them. It's must be a `make` thing.