#!/bin/bash

echo "=== QUICK STUTTER TEST ==="
echo "Running simplified test to capture j/k stuttering..."

# Run the simple test
nvim --headless -c "
luafile ~/.config/simple_stutter_test.lua |
SimpleStutterTest |
qa
" 2>&1

echo
echo "=== EXTERNAL KEYSTROKE SIMULATION ==="
echo "Testing with external key simulation (more realistic)..."

# Create a test script that simulates holding j
cat > /tmp/test_j_hold.vim << 'EOF'
" Open test file
edit /tmp/simple_stutter_test.js
normal! gg

" Enable profiling
profile start /tmp/j_hold_profile.log
profile func *

" Simulate holding j key (500 times with realistic timing)
let start_time = reltime()
for i in range(500)
    let iter_start = reltime()
    normal! j
    redraw
    let iter_time = reltimestr(reltime(iter_start))
    if str2float(iter_time) > 0.03
        echo "Stutter at iteration " . i . ": " . iter_time . "s"
    endif
    sleep 20m
endfor
let total_time = reltimestr(reltime(start_time))
echo "Total time for 500 j presses: " . total_time . "s"

profile pause
profile dump
quit
EOF

echo "Running external keystroke simulation..."
nvim -s /tmp/test_j_hold.vim 2>&1

echo
echo "=== RESULTS SUMMARY ==="

# Check if we have results
if [ -f /tmp/simple_stutter_results.txt ]; then
    echo "Simple test results:"
    head -10 /tmp/simple_stutter_results.txt
fi

if [ -f /tmp/j_hold_profile.log ]; then
    echo
    echo "Profile results (top functions):"
    grep "^FUNCTION" /tmp/j_hold_profile.log | sort -k5 -nr | head -5
fi

echo
echo "Files generated:"
echo "  /tmp/simple_stutter_results.txt - Simple test timing data"
echo "  /tmp/j_hold_profile.log - Function profiling during j keypresses"
echo "  /tmp/test_j_hold.vim - Vim script used for testing"

echo
echo "Run this test multiple times to confirm consistent results."
