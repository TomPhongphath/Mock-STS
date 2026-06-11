#!/usr/bin/env sh
set -eu

SKIP_UPDATE=0
if [ "${1:-}" = "--skip-update-existing" ]; then
  SKIP_UPDATE=1
fi

ensure_repo() {
  owner="$1"
  repo="$2"
  target_path="$repo"

  if [ -d "$target_path/.git" ]; then
    if git -C "$target_path" rev-parse --verify HEAD >/dev/null 2>&1; then
      if [ "$SKIP_UPDATE" -eq 0 ]; then
        echo "Updating $repo ..."
        git -C "$target_path" fetch --all --prune
      else
        echo "Skipping update for existing repo $repo"
      fi
      return
    fi

    echo "Repository $repo has no valid HEAD, re-cloning ..."
    rm -rf "$target_path"
  fi

  if [ -d "$target_path" ]; then
    if [ "$(ls -A "$target_path" 2>/dev/null || true)" != "" ]; then
      echo "ERROR: Path '$target_path' exists but is not a git repository. Move or delete it, then re-run bootstrap."
      exit 1
    fi
    rmdir "$target_path"
  fi

  remote_url="https://github.com/$owner/$repo.git"
  echo "Cloning $repo ..."
  git clone --depth 1 "$remote_url" "$target_path"
}

echo "Ensuring STS source repositories ..."
ensure_repo "TomPhongphath" "STS-ADM"
ensure_repo "TomPhongphath" "STS-ALERT"
ensure_repo "TomPhongphath" "STS-Common"
ensure_repo "TomPhongphath" "STS-DASHBOARD"
ensure_repo "TomPhongphath" "STS-INSTALL"
ensure_repo "TomPhongphath" "STS-INVENTORY-CONTROL"
ensure_repo "TomPhongphath" "STS-MASTER"
ensure_repo "TomPhongphath" "STS-NOC"
ensure_repo "TomPhongphath" "SCS-TELEPORT"
ensure_repo "TomPhongphath" "sts-portal"

echo "Ensuring persistent data directories ..."
mkdir -p \
  data/jenkins_home \
  data/prometheus

if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

echo "Bootstrap completed."
