#!/bin/bash

# Cron wrapper script for auto_poster.rb
# This script handles paths and environment properly for cron execution

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script directory
cd "$SCRIPT_DIR"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Add common Ruby paths (adjust if needed)
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# If using rbenv, add rbenv to path
if [ -d "$HOME/.rbenv" ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
fi

# If using RVM, load RVM
if [ -f "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Run the poster with logging
echo "$(date): Starting auto_poster..." >> logs/cron.log
ruby auto_poster.rb post >> logs/cron.log 2>&1
echo "$(date): Auto_poster completed" >> logs/cron.log
