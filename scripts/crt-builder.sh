#!/usr/bin/env bash

# The crt-builder is used to detemine build metadata and create Vault builds.
# We use it in build-vault.yml for building release artifacts with CRT. It is
# also used by Enos for artifact_source:local scenario variants.

set -euo pipefail

# We don't want to get stuck in some kind of interactive pager
export GIT_PAGER=cat

# Get the build date from the latest commit since it can be used across all
# builds
function build_date() {
  # It's tricky to do an RFC3339 format in a cross platform way, so we hardcode UTC
  : "${DATE_FORMAT:="%Y-%m-%dT%H:%M:%SZ"}"
  git show --no-show-signature -s --format=%cd --date=format:"$DATE_FORMAT" HEAD
}

# Get the revision, which is the latest commit SHA
function build_revision() {
  git rev-parse HEAD
}

# Determine our repository by looking at our origin URL
function repo() {
  basename -s .git "$(git config --get remote.origin.url)"
}

# Determine the root directory of the repository
function repo_root() {
  git rev-parse --show-toplevel
}

# Build the UI
function build_ui() {
  local repo_root
  repo_root=$(repo_root)

  pushd "$repo_root"
  mkdir -p http/web_ui
  popd
  pushd "$repo_root/ui"
  yarn install --ignore-optional
  npm rebuild node-sass
  yarn --verbose run build
  popd
}

# Build Vault
function build() {
  local version
  local revision
  local prerelease
  local build_date
  local ldflags
  local msg

  # Get or set our basic build metadata
  revision=$(build_revision)
  build_date=$(build_date) #
  : "${BIN_PATH:="dist/"}" #if not run by actions-go-build (enos local) then set this explicitly
  : "${GO_TAGS:=""}"
  : "${KEEP_SYMBOLS:=""}"

  # Build our ldflags
  msg="--> Building Vault revision $revision, built $build_date"

  # Strip the symbol and dwarf information by default
  if [ -n "$KEEP_SYMBOLS" ]; then
    ldflags=""
  else
    ldflags="-s -w "
  fi

  # if building locally with enos - don't need to set version/prerelease/metadata as the default from version_base.go will be used
  ldflags="${ldflags} -X github.com/hashicorp/vault/sdk/version.GitCommit=$revision -X github.com/hashicorp/vault/sdk/version.BuildDate=$build_date"

  if [[ ${BASE_VERSION+x} ]]; then
    msg="${msg}, base version ${BASE_VERSION}"
    ldflags="${ldflags} -X github.com/hashicorp/vault/sdk/version.Version=$BASE_VERSION"
  fi

  if [[ ${PRERELEASE_VERSION+x} ]]; then
    msg="${msg}, prerelease ${PRERELEASE_VERSION}"
    ldflags="${ldflags} -X github.com/hashicorp/vault/sdk/version.VersionPrerelease=$PRERELEASE_VERSION"
  fi

  if [[ ${VERSION_METADATA+x} ]]; then
    msg="${msg}, metadata ${VERSION_METADATA}"
    ldflags="${ldflags} -X github.com/hashicorp/vault/sdk/version.VersionMetadata=$VERSION_METADATA"
  fi

  # Build vault
  echo "$msg"
  go build -o "$BIN_PATH" -tags "$GO_TAGS" -ldflags "$ldflags" -trimpath -buildvcs=false
}

# Prepare legal requirements for packaging
function prepare_legal() {
  : "${PKG_NAME:="vault"}"

  pushd "$(repo_root)"
  mkdir -p dist
  curl -o dist/EULA.txt https://eula.hashicorp.com/EULA.txt
  curl -o dist/TermsOfEvaluation.txt https://eula.hashicorp.com/TermsOfEvaluation.txt
  mkdir -p ".release/linux/package/usr/share/doc/$PKG_NAME"
  cp dist/EULA.txt ".release/linux/package/usr/share/doc/$PKG_NAME/EULA.txt"
  cp dist/TermsOfEvaluation.txt ".release/linux/package/usr/share/doc/$PKG_NAME/TermsOfEvaluation.txt"
  popd
}

# Run the CRT Builder
function main() {
  case $1 in
  build)
    build
  ;;
  build-ui)
    build_ui
  ;;
  date)
    build_date
  ;;
  prepare-legal)
    prepare_legal
  ;;
  revision)
    build_revision
  ;;
  *)
    echo "unknown sub-command" >&2
    exit 1
  ;;
  esac
}

main "$@"
