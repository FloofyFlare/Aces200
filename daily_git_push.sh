#!/bin/bash
# Script to add, commit, and push all changes to the master branch

# Change to the repository directory
cd . || exit

# Stage all changes
git add .

# Commit with a timestamp message
git commit -m "Automated commit on $(date +"%Y-%m-%d %H:%M:%S")"

# Push to the master branch
git push -u origin master
