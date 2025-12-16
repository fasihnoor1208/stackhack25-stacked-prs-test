#!/bin/bash

# Quick script to create a test stack for Graphite
# Usage: ./create-test-stack.sh [stack-name] [num-branches]
# Example: ./create-test-stack.sh my-feature 3

set -e

STACK_NAME=${1:-"test-stack"}
NUM_BRANCHES=${2:-3}
TEST_FILE="${STACK_NAME}.md"

echo "🥞 Creating test stack: $STACK_NAME with $NUM_BRANCHES branches"
echo "================================================"

# Make sure we're on main and up to date
echo "📥 Syncing with main..."
git checkout main
git pull origin main

# Create the test file with initial content
echo "# Test Stack: $STACK_NAME" > "$TEST_FILE"
echo "" >> "$TEST_FILE"
echo "Created at: $(date)" >> "$TEST_FILE"

# Create each branch in the stack
for i in $(seq 1 $NUM_BRANCHES); do
    echo ""
    echo "🔨 Creating branch $i of $NUM_BRANCHES..."
    
    # Add content to the test file
    echo "" >> "$TEST_FILE"
    echo "## Feature $i" >> "$TEST_FILE"
    echo "- Added in branch $i" >> "$TEST_FILE"
    echo "- Timestamp: $(date +%H:%M:%S)" >> "$TEST_FILE"
    
    # Stage and create branch with Graphite
    git add "$TEST_FILE"
    gt create -a -m "${STACK_NAME}-f${i}"
    
    echo "✅ Created: ${STACK_NAME}-f${i}"
done

echo ""
echo "================================================"
echo "🎉 Stack created! Summary:"
echo "   - Test file: $TEST_FILE"
echo "   - Branches: $NUM_BRANCHES"
echo ""

# Ask if user wants to submit
read -p "🚀 Submit stack to GitHub? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📨 Submitting stack..."
    gt submit
    echo "✅ Stack submitted!"
else
    echo "💡 Run 'gt submit' when you're ready to create PRs"
fi

echo ""
echo "📋 Useful commands:"
echo "   gt log          - View the stack"
echo "   gt submit       - Submit/update PRs"
echo "   gt down/up      - Navigate the stack"
echo "   gt repo sync    - Sync after merges"

