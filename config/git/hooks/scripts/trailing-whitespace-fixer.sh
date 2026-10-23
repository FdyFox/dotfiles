#!/usr/bin/env bash

FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.py$|\.js$|\.css$|\.html$|\.yml$|\.yaml$|\.json$|\.sh$|\.md$')

for FILE in $FILES; do
    # Skip partially staged files, otherwise git add would commit the whole file
    if ! git diff --quiet -- "$FILE"; then
        printf "⚠️  Skipped %s (partially staged).\n" "$FILE"
        continue
    fi

    # Remove trailing whitespace
    sed -i 's/[[:space:]]\+$//' "$FILE"

    # Add modified file to the staging area
    git add "$FILE"
done

printf "✅ Trailing whitespaces removed for staged files.\n"
