#!/usr/bin/env bash
# Re-apply the current matugen palette to every running kitty instance.
# Kept as a script (not an inline post_hook) because matugen runs hooks
# through the user's login shell, which may be fish and cannot parse bash.

for p in $(pgrep -x kitty); do
	kitty @ --to "unix:@kitty-$p" set-colors --all --configured \
		"$HOME/.config/kitty/matugen.conf" >/dev/null 2>&1 || true
done
