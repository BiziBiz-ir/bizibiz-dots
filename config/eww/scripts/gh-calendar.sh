#!/usr/bin/env bash
# gh-calendar — renders the GitHub contributions calendar to a PNG and
# prints its path (timestamped filename so eww always reloads the image).
#
# With a token in ~/.config/gh-contribs-token (classic PAT, read:user scope),
# it uses the GraphQL API which INCLUDES private contributions.
# Without a token it scrapes the public calendar page.

set -u

USER="${1:-BiziBiz-ir}"
TOKEN_FILE="$HOME/.config/gh-contribs-token"
JSON_CACHE="$HOME/.cache/gh-contribs-$USER.json"
HTML_CACHE="$HOME/.cache/gh-contribs-$USER.html"
MAX_AGE=$((60 * 60))

# share one data fetch with gh-contribs.sh
if [[ -s $TOKEN_FILE ]]; then
    if [[ ! -f $JSON_CACHE || $(date +%s -r "$JSON_CACHE") -lt $(( $(date +%s) - MAX_AGE )) ]]; then
        q='query($login:String!){ user(login:$login){ contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount color } } } } } }'
        timeout 15 curl -sS --compressed \
            -H "Authorization: Bearer $(cat "$TOKEN_FILE")" \
            -H "Content-Type: application/json" \
            -d "$(jq -n --arg q "$q" --arg l "$USER" '{query:$q,variables:{login:$l}}')" \
            "https://api.github.com/graphql" -o "$JSON_CACHE.tmp" \
            && jq -e '.data.user.contributionsCollection' "$JSON_CACHE.tmp" >/dev/null \
            && mv "$JSON_CACHE.tmp" "$JSON_CACHE"
    fi
    DATA="$JSON_CACHE"
else
    if [[ ! -f $HTML_CACHE || $(date +%s -r "$HTML_CACHE") -lt $(( $(date +%s) - MAX_AGE )) ]]; then
        timeout 15 curl -sS --compressed \
            "https://github.com/users/$USER/contributions" -o "$HTML_CACHE.tmp" \
            && mv "$HTML_CACHE.tmp" "$HTML_CACHE"
    fi
    DATA="$HTML_CACHE"
fi

ts=$(date +%s)
tmp="$HOME/.cache/.gh-cal-$ts.png"
out="$HOME/.cache/gh-calendar-$ts.png"
python3 "$HOME/.config/eww/scripts/gh-cal-render.py" "$DATA" "$tmp" || true

# print newest png (fall back to any previous one so the widget never blanks)
if [[ -f $tmp ]]; then
    rm -f "$HOME"/.cache/gh-calendar-*.png 2>/dev/null
    mv "$tmp" "$out"
    echo "$out"
else
    ls -1t "$HOME"/.cache/gh-calendar-*.png 2>/dev/null | head -1
fi
