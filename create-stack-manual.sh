#!/bin/bash

# Script to manually create a stacked PR workflow using only git commands
# Usage: ./create-stack-manual.sh [stack-name] [num-branches]
# Example: ./create-stack-manual.sh my-feature 3

set -e

STACK_NAME=${1:-"manual-stack"}
NUM_BRANCHES=${2:-3}
TEST_FILE="${STACK_NAME}.md"
BASE_BRANCH="main"

echo "🥞 Creating manual stack: $STACK_NAME with $NUM_BRANCHES branches"
echo "================================================"

# Make sure we're on main and up to date
echo "📥 Syncing with $BASE_BRANCH..."
git checkout $BASE_BRANCH
git pull origin $BASE_BRANCH

# Track the parent branch for each new branch
PARENT_BRANCH=$BASE_BRANCH

# Create the test file with initial content
echo "# Manual Stack: $STACK_NAME" > "$TEST_FILE"
echo "" >> "$TEST_FILE"
echo "Created at: $(date)" >> "$TEST_FILE"

# Store branch names for later reference
BRANCH_NAMES=()

# Create each branch in the stack
for i in $(seq 1 $NUM_BRANCHES); do
    BRANCH_NAME="${STACK_NAME}-f${i}"
    BRANCH_NAMES+=("$BRANCH_NAME")
    
    echo ""
    echo "🔨 Creating branch $i of $NUM_BRANCHES: $BRANCH_NAME"
    echo "   (branching from: $PARENT_BRANCH)"
    
    # Create the new branch from the current parent
    git checkout -b "$BRANCH_NAME"
    
    # Add content to the test file
    echo "" >> "$TEST_FILE"
    echo "## Feature $i" >> "$TEST_FILE"
    echo "- Added in branch $i" >> "$TEST_FILE"
    echo "- Timestamp: $(date +%H:%M:%S)" >> "$TEST_FILE"
    
    # Stage and commit the changes
    git add "$TEST_FILE"
    git commit -m "feat: add feature $i for $STACK_NAME"
    
    # Small delay to prevent index.lock race conditions
    sleep 0.2
    
    echo "✅ Created and committed: $BRANCH_NAME"
    
    # The next branch will be based on this one (that's what makes it a stack!)
    PARENT_BRANCH=$BRANCH_NAME
done

echo ""
echo "================================================"
echo "🎉 Stack created! Summary:"
echo "   - Test file: $TEST_FILE"
echo "   - Branches: $NUM_BRANCHES"
echo ""
echo "📊 Stack structure:"
echo "   $BASE_BRANCH"
for i in "${!BRANCH_NAMES[@]}"; do
    indent=$(printf '   %.0s' $(seq 0 $i))
    echo "   ${indent}└── ${BRANCH_NAMES[$i]}"
done
echo ""

# Ask if user wants to push
read -p "🚀 Push all branches to GitHub? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📨 Pushing all branches..."
    for branch in "${BRANCH_NAMES[@]}"; do
        echo "   Pushing $branch..."
        git push -u origin "$branch"
    done
    echo "✅ All branches pushed!"
    echo ""
    
    # Ask if user wants to create PRs
    read -p "📝 Create PRs with correct base branches? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔗 Creating PRs..."
        PR_URLS=()
        
        for i in "${!BRANCH_NAMES[@]}"; do
            branch="${BRANCH_NAMES[$i]}"
            
            if [ $i -eq 0 ]; then
                base="$BASE_BRANCH"
            else
                base="${BRANCH_NAMES[$((i-1))]}"
            fi
            
            echo "   Creating PR for $branch (base: $base)..."
            
            # Create PR with gh CLI (no description)
            pr_url=$(gh pr create \
                --base "$base" \
                --head "$branch" \
                --title "feat: add feature $((i+1)) for $STACK_NAME" \
                --body "" 2>&1)
            
            if [ $? -eq 0 ]; then
                PR_URLS+=("$pr_url")
                echo "   ✅ Created: $pr_url"
            else
                echo "   ❌ Failed to create PR for $branch"
                echo "      $pr_url"
            fi
        done
        
        echo ""
        echo "🎯 PRs created successfully!"
        echo ""
        echo "📋 PR URLs:"
        for url in "${PR_URLS[@]}"; do
            echo "   $url"
        done
        echo ""
        echo "⚠️  Remember: Merge PRs from bottom to top of the stack!"
    else
        echo "📝 Create PRs manually on GitHub:"
        echo "   - For ${BRANCH_NAMES[0]}: base = $BASE_BRANCH"
        for i in $(seq 1 $((NUM_BRANCHES - 1))); do
            echo "   - For ${BRANCH_NAMES[$i]}: base = ${BRANCH_NAMES[$((i-1))]}"
        done
    fi
else
    echo "💡 Run these commands when ready to push:"
    for branch in "${BRANCH_NAMES[@]}"; do
        echo "   git push -u origin $branch"
    done
fi

echo ""
echo "📋 Useful git commands for stacks:"
echo "   git log --oneline --graph --all    - View branch structure"
echo "   git checkout <branch>              - Switch to a branch"
echo "   git rebase <parent>                - Update branch with parent changes"
echo ""
echo "🔄 To update the stack after changes to a branch:"
echo "   1. Make changes on the bottom branch"
echo "   2. For each child branch: git checkout <child> && git rebase <parent>"
echo "   3. Force push updated branches: git push --force-with-lease origin <branch>"

