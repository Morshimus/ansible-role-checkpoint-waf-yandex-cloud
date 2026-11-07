#!/usr/bin/env bash
# Updates the Diffusion settings table in README.md with resolved versions
# from diffusion.lock. Intended to run in CI after diffusion deps update.
set -euo pipefail

LOCK_FILE="diffusion.lock"
README="README.md"

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "Lock file not found: $LOCK_FILE"
  exit 1
fi

if [[ ! -f "$README" ]]; then
  echo "README not found: $README"
  exit 1
fi

# ---------------------------------------------------------------------------
# Parse diffusion.lock (simple YAML — no nested structures we care about)
# We build an associative array: display_name -> resolved_version
# ---------------------------------------------------------------------------
declare -A VERSIONS

current_section=""
current_name=""
current_namespace=""

while IFS= read -r line; do
  # Detect top-level sections
  if [[ "$line" =~ ^collections: ]]; then
    current_section="collections"
    continue
  elif [[ "$line" =~ ^roles: ]]; then
    current_section="roles"
    continue
  elif [[ "$line" =~ ^tools: ]]; then
    current_section="tools"
    continue
  elif [[ "$line" =~ ^python: ]]; then
    current_section="python"
    continue
  elif [[ "$line" =~ ^[a-z] && ! "$line" =~ ^[[:space:]] ]]; then
    current_section=""
    continue
  fi

  # Inside a list item (starts with "    - " or "      ")
  case "$current_section" in
    collections|roles|tools)
      # New list item
      if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+name:[[:space:]]*(.+) ]]; then
        current_name="${BASH_REMATCH[1]}"
        current_namespace=""
      elif [[ "$line" =~ ^[[:space:]]+namespace:[[:space:]]*(.+) ]]; then
        current_namespace="${BASH_REMATCH[1]}"
      elif [[ "$line" =~ ^[[:space:]]+resolved_version:[[:space:]]*(.+) ]]; then
        resolved="${BASH_REMATCH[1]}"
        case "$current_section" in
          tools)
            # Tools use their plain name: ansible, molecule, ansible-lint, yamllint
            VERSIONS["$current_name"]="$resolved"
            ;;
          collections)
            # Collections: community.general, community.docker
            # Lock name is e.g. "default.general", namespace "community"
            short="${current_name#default.}"
            display="${current_namespace}.${short}"
            VERSIONS["$display"]="$resolved"
            ;;
          roles)
            # Roles: konstruktoid.docker_rootless
            short="${current_name#default.}"
            display="${current_namespace}.${short}"
            VERSIONS["$display"]="$resolved"
            ;;
        esac
      fi
      ;;
  esac
done < "$LOCK_FILE"

echo "Parsed versions from lock file:"
for key in "${!VERSIONS[@]}"; do
  echo "  $key = ${VERSIONS[$key]}"
done

# ---------------------------------------------------------------------------
# Update README table rows that match the pattern:
#   | <Name> | `<constraint>` → resolved `<old_version>` |
# We replace <old_version> with the new resolved version.
# ---------------------------------------------------------------------------
changed=0

# Map from README display key to lock key
declare -A README_KEY_MAP=(
  ["Ansible"]="ansible"
  ["ansible-lint"]="ansible-lint"
  ["molecule"]="molecule"
  ["yamllint"]="yamllint"
  ["\`community.general\`"]="community.general"
  ["\`community.docker\`"]="community.docker"
  ["\`konstruktoid.docker_rootless\`"]="konstruktoid.docker_rootless"
)

for readme_key in "${!README_KEY_MAP[@]}"; do
  lock_key="${README_KEY_MAP[$readme_key]}"
  new_version="${VERSIONS[$lock_key]:-}"

  if [[ -z "$new_version" ]]; then
    echo "Warning: no resolved version found for $lock_key, skipping"
    continue
  fi

  # Build a sed pattern that matches the table row and replaces the resolved version.
  # The table row looks like:
  #   | Ansible | `>=13.0.0` → resolved `14.0.0a2` |
  # We need to match "resolved \`<anything>\`" and replace the version inside the backticks.
  # Use a capture group for everything before "resolved `" and after the closing "`".

  # Escape backticks and pipes for sed
  # Pattern: (| <key> | .* resolved `)OLD_VERSION(` |)
  # We match the row by the key in the first column and replace only the resolved version.

  if sed --version 2>/dev/null | grep -q GNU; then
    # GNU sed
    sed -i -E "s/(\\| ${readme_key} \\|[^|]*resolved \`)([^\`]+)(\`[[:space:]]*\\|)/\\1${new_version}\\3/" "$README"
  else
    # BSD sed (macOS)
    sed -i '' -E "s/(\\| ${readme_key} \\|[^|]*resolved \`)([^\`]+)(\`[[:space:]]*\\|)/\\1${new_version}\\3/" "$README"
  fi
done

# Check if README actually changed
if git diff --quiet "$README" 2>/dev/null; then
  echo "README.md is already up to date."
else
  echo "README.md updated with new resolved versions."
  changed=1
fi

exit 0
