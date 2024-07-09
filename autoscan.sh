#!/bin/bash

# Function to get absolute path (handles symlinks)
function get_absolute_path() {
  echo $(readlink -f "$1")
}

# Set directory variables (modify as needed)
script_dir="$(pwd)"  # Directory containing this script (A)
target_dir="/home/concavang/workspace/pentest"                     # Directory containing subdirectories (B)
env_file="$script_dir/.env"                    # Path to .env file (in A)
docker_compose_file="$script_dir/docker-compose.yml"  # Path to docker-compose.yml (in A)

# Check if directories and files exist
if [[ ! -d "$target_dir" ]]; then
  echo "Error: Directory '$target_dir' does not exist."
  exit 1
fi

if [[ ! -f "$env_file" ]]; then
  echo "Error: File '$env_file' does not exist."
  exit 1
fi

if [[ ! -f "$docker_compose_file" ]]; then
  echo "Error: File '$docker-compose_file' does not exist."
  exit 1
fi

# Loop through subdirectories in directory B (not recursive)
for subdir in "$target_dir"/*; do
  # Skip files and non-directories
  if [[ ! -d "$subdir" ]]; then
    continue
  fi
  echo $subdir

  # Get absolute path of the subdirectory
  absolute_path=$(get_absolute_path "$subdir")

  # Update .env file
  sed -i "s|SRC=.*|SRC=$absolute_path|" "$env_file"

  # Run docker-compose up (wait for completion)
  docker-compose -f "$docker_compose_file" up --force-recreate
  wait

  # Restore original .env (optional, uncomment if needed)
  # sed -i "s|SRC=$absolute_path|SRC=.*|" "$env_file"
done

echo "Process completed."

