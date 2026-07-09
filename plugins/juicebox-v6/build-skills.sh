#!/bin/bash
# Build individual skill zips for Claude Console upload
# Each zip is self-contained and ready for drag-and-drop

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
SHARED_DIR="$SCRIPT_DIR/shared"
REFS_DIR="$SCRIPT_DIR/references"
OUTPUT_DIR="$SCRIPT_DIR/dist"

# Clean and create output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Building skills for Claude Console..."
echo "Output: $OUTPUT_DIR"
echo ""

# Build ALL skills
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name=$(basename "$skill_dir")

  if [ ! -d "$skill_dir" ]; then
    echo "⚠️  Skipping $skill_name (not found)"
    continue
  fi

  echo "📦 Packaging $skill_name..."

  # Create temp directory for this skill
  tmp_dir=$(mktemp -d)
  skill_tmp="$tmp_dir/$skill_name"
  mkdir -p "$skill_tmp"

  # Copy skill contents
  cp -r "$skill_dir"/* "$skill_tmp/"

  # Bundle shared resources if skill references them
  if grep -q "shared/" "$skill_tmp/SKILL.md" 2>/dev/null; then
    mkdir -p "$skill_tmp/shared"
    cp "$SHARED_DIR/chain-config.json" "$skill_tmp/shared/" 2>/dev/null || true
    cp "$SHARED_DIR/styles.css" "$skill_tmp/shared/" 2>/dev/null || true
    cp "$SHARED_DIR/wallet-utils.js" "$skill_tmp/shared/" 2>/dev/null || true
  fi

  # Bundle references if skill references them
  if grep -q "references/" "$skill_tmp/SKILL.md" 2>/dev/null; then
    mkdir -p "$skill_tmp/references"
    cp "$REFS_DIR"/*.md "$skill_tmp/references/" 2>/dev/null || true
  fi

  # Create zip
  (cd "$tmp_dir" && zip -rq "$OUTPUT_DIR/$skill_name.zip" "$skill_name")

  # Get zip size
  size=$(ls -lh "$OUTPUT_DIR/$skill_name.zip" | awk '{print $5}')
  echo "   ✓ $skill_name.zip ($size)"

  # Cleanup
  rm -rf "$tmp_dir"
done

echo ""
echo "✅ Done! All skill zips ready in: $OUTPUT_DIR"
echo ""
echo "To upload: Drag any .zip file into Claude Console's skill upload dialog"
