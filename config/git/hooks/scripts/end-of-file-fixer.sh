#!/usr/bin/env bash

FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.py$|\.js$|\.css$|\.html$|\.yml$|\.yaml$|\.json$|\.sh$|\.md$')

for FILE in $FILES; do
    # Skip partially staged files, otherwise git add would commit the whole file
    if ! git diff --quiet -- "$FILE"; then
        printf "⚠️  Skipped %s (partially staged).\n" "$FILE"
        continue
    fi

    # Ensure the file ends with a single newline
    if [ -s "$FILE" ] && [ "$(tail -c 1 "$FILE")" != "" ]; then
        echo "" >>"$FILE"
    fi

    # Remove excess newlines at the end of the file (ensure only one)
    sed -i ':a;/^\n*$/{$d;N;};/\n$/ba' "$FILE"

    # Add modified file to the staging area
    git add "$FILE"
done

printf "✅ End-of-file newlines fixed for staged files.\n"
