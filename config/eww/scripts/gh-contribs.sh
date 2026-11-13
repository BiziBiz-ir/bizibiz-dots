#!/usr/bin/env bash
# gh-contribs — total contributions in the last year for a GitHub profile.
# With a token in ~/.config/gh-contribs-token (classic PAT, read:user scope)
# the count includes private contributions; without it, public only.

set -u

USER="${1:-BiziBiz-ir}"
TOKEN_FILE="$HOME/.config/gh-contribs-token"
JSON_CACHE="$HOME/.cache/gh-contribs-$USER.json"
COUNT_CACHE="$HOME/.cache/gh-contribs-$USER"
MAX_AGE=$((60 * 60))

if [[ -f $COUNT_CACHE && $(date +%s -r "$COUNT_CACHE") -ge $(( $(date +%s) - MAX_AGE )) ]]; then
    cat "$COUNT_CACHE"
    exit 0
fi

count=""

# token path: JSON cache written by gh-calendar.sh (freshness managed there)
if [[ -s $TOKEN_FILE && -f $JSON_CACHE ]]; then
    count=$(jq -r '.data.user.contributionsCollection.contributionCalendar.totalContributions // empty' "$JSON_CACHE" 2>/dev/null)
fi

# fallback: scrape the public calendar page
if [[ -z $count ]]; then
    html=$(timeout 15 curl -sS --compressed \
        "https://github.com/users/$USER/contributions" 2>/dev/null) || { cat "$COUNT_CACHE" 2>/dev/null || echo "0"; exit 0; }

    count=$(printf '%s' "$html" \
        | tr '\n' ' ' \
        | grep -oE 'id="js-contribution-activity-description"[^>]*>[[:space:]]*[0-9]+' \
        | grep -oE '[0-9]+$' \
        | head -1)

    # keep the html around so gh-calendar.sh can reuse it
    printf '%s' "$html" > "$HOME/.cache/gh-contribs-$USER.html" 2>/dev/null
fi

count=${count:-0}
echo "$count" > "$COUNT_CACHE"
echo "$count"
