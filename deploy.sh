#!/bin/sh

# If a command fails then the deploy stops
#set -e


# clean Public folder
cd yairgd.github.io
git rm -rf .
git clean -fxd
git reset

cd ..
# Build the project.
#hugo # if using a theme, replace with `hugo -t <YOURTHEME>`
hugo --gc --minify --cleanDestinationDir

# Go To Public folder
cd yairgd.github.io
# Add changes to git.
printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git add .
git commit -m "$msg"

# Push source and build repos.
git push origin master
