#!/bin/bash
# Rename only the repacked copy after MonkeyDev verification and injection,
# before the project's existing code signing. Input IPA/dylib are untouched.
set -euo pipefail

: "${1:?Pass repacked .app directory}"
app="$1"
old_name="BluedEnhancer.2.8.9_Finala_arm64e.dylib"
new_name="YuJianProCore.dylib"
old_path="$app/$old_name"
new_path="$app/$new_name"
main="$app/Blued"
old_load="@executable_path/$old_name"
new_load="@executable_path/$new_name"

[[ -d "$app" && -f "$main" && ! -L "$main" ]] || {
  echo "PluginBrand: missing repacked executable: $main" >&2
  exit 1
}

dependencies=$(/usr/bin/xcrun otool -L "$main")
has_old=NO
has_new=NO
if /usr/bin/grep -Fq "$old_load (" <<<"$dependencies"; then has_old=YES; fi
if /usr/bin/grep -Fq "$new_load (" <<<"$dependencies"; then has_new=YES; fi

if [[ -f "$old_path" && ! -L "$old_path" && ! -L "$new_path" &&
      ( ! -e "$new_path" || -f "$new_path" ) &&
      "$has_old" == YES && "$has_new" == NO ]]; then
  [[ "$(/usr/bin/lipo -archs "$old_path")" == arm64e ]] || {
    echo "PluginBrand: unexpected plugin architecture" >&2
    exit 1
  }
  # MonkeyDev may preserve the renamed file from a previous build as an
  # Xcode-owned output. The main executable still loads this build's original
  # library, so replace that stale regular file with the current input library.
  # Shorter replacement path, still an LC_LOAD_WEAK_DYLIB dependency.
  /usr/bin/xcrun install_name_tool -change "$old_load" "$new_load" "$main"
  /bin/mv -f "$old_path" "$new_path"
elif [[ ! -e "$old_path" && -f "$new_path" && ! -L "$new_path" &&
        "$has_old" == NO && "$has_new" == YES ]]; then
  : # Already renamed in this repacked app.
else
  echo "PluginBrand: invalid plugin filename/loading state (loads original=$has_old, renamed=$has_new)" >&2
  /bin/ls -ld "$old_path" "$new_path" >&2 || true
  exit 1
fi

dependencies=$(/usr/bin/xcrun otool -L "$main")
[[ -f "$new_path" && ! -e "$old_path" ]] || exit 1
/usr/bin/grep -Fq "$new_load (" <<<"$dependencies" || exit 1
if /usr/bin/grep -Fq "$old_load (" <<<"$dependencies"; then
  echo "PluginBrand: original loading path remains" >&2
  exit 1
fi
echo "PluginBrand: loaded from $new_name; signed in next phase"

# MonkeyDev expects the project's original product name while packing. Rename
# the injected copy afterwards so its copy/injection conventions keep working.
hook_old="$app/Frameworks/libbluedXHookDylib.dylib"
hook_new="$app/Frameworks/BearMeetPro.dylib"
hook_old_load="@executable_path/Frameworks/libbluedXHookDylib.dylib"
hook_new_load="@executable_path/Frameworks/BearMeetPro.dylib"
dependencies=$(/usr/bin/xcrun otool -L "$main")
if [[ -f "$hook_old" && ! -L "$hook_old" && ! -L "$hook_new" &&
      ( ! -e "$hook_new" || -f "$hook_new" ) ]] &&
   /usr/bin/grep -Fq "$hook_old_load (" <<<"$dependencies"; then
  /usr/bin/xcrun install_name_tool -change "$hook_old_load" "$hook_new_load" "$main"
  /usr/bin/xcrun install_name_tool -id "$hook_new_load" "$hook_old"
  /bin/mv -f "$hook_old" "$hook_new"
elif [[ ! -e "$hook_old" && ! -L "$hook_old" &&
        -f "$hook_new" && ! -L "$hook_new" ]] &&
     /usr/bin/grep -Fq "$hook_new_load (" <<<"$dependencies" &&
     ! /usr/bin/grep -Fq "$hook_old_load (" <<<"$dependencies"; then
  : # Already renamed in this repacked app.
else
  echo "PluginBrand: invalid BearMeetPro filename/loading state" >&2
  exit 1
fi
echo "PluginBrand: project hook loaded from BearMeetPro.dylib; signed in next phase"
