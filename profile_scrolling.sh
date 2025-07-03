#!/bin/bash

# External profiling script for j/k scrolling performance
# This script uses Neovim's built-in profiling to capture bottlenecks

echo "=== NEOVIM SCROLLING PERFORMANCE PROFILER ==="
echo "This script will systematically test and profile j/k scrolling performance"
echo

# Create test file if it doesn't exist
TEST_FILE="/tmp/nvim_profile_test.js"
if [ ! -f "$TEST_FILE" ]; then
    echo "Creating test file for profiling..."
    cat > "$TEST_FILE" << 'EOF'
// Test file for performance profiling
function performanceTest() {
    console.log("Testing performance");

    // Multiple function definitions to trigger parsing
    const data = {
        value: 1,
        nested: {
            array: [1, 2, 3, 4, 5],
            object: { deep: true }
        }
    };

    // TODO: This is a comment for highlighting
    for (let i = 0; i < 100; i++) {
        console.log(`Processing item ${i}`);
        if (i % 10 === 0) {
            // FIXME: Performance issue here
            data.nested.array.push(i);
        }
    }

    return data;
}

// Repeat this pattern many times
EOF

    # Duplicate the content to create a larger file
    for i in {1..50}; do
        sed "s/performanceTest/performanceTest$i/g" "$TEST_FILE" >> "${TEST_FILE}.tmp"
        echo "" >> "${TEST_FILE}.tmp"
    done
    mv "${TEST_FILE}.tmp" "$TEST_FILE"
    echo "Test file created with $(wc -l < "$TEST_FILE") lines"
fi

echo
echo "=== BASELINE PERFORMANCE MEASUREMENT ==="

# Test 1: Profile startup with the test file
echo "1. Profiling startup performance..."
nvim --startuptime /tmp/startup_profile.log "$TEST_FILE" +q
echo "   Startup profiling complete"

# Test 2: Run the internal stutter test
echo "2. Running systematic stutter detection test..."
nvim --headless -c "luafile ~/.config/stutter_test.lua" -c "StutterTest" -c "qa" 2>&1 | tee /tmp/stutter_output.log
echo "   Internal stutter test complete"

# Test 3: Profile function calls during scrolling
echo "3. Profiling function calls during scrolling simulation..."
nvim --headless -c "
    edit $TEST_FILE |
    profile start /tmp/scroll_profile.log |
    profile func * |
    profile file * |
    normal! gg |
    lua for i=1,50 do vim.cmd('normal! j'); vim.wait(20) end |
    profile pause |
    profile dump |
    qa
" 2>&1

echo "   Function profiling complete"

# Test 4: Memory usage during scrolling
echo "4. Testing memory usage progression..."
nvim --headless -c "
    edit $TEST_FILE |
    normal! gg |
    lua
        local mem_start = collectgarbage('count')
        print('Memory at start: ' .. mem_start .. ' KB')
        for i=1,100 do
            vim.cmd('normal! j')
            if i % 25 == 0 then
                local mem_current = collectgarbage('count')
                print('Memory after ' .. i .. ' scrolls: ' .. mem_current .. ' KB (delta: ' .. (mem_current - mem_start) .. ')')
            end
            vim.wait(10)
        end
    |
    qa
" 2>&1 | tee /tmp/memory_progression.log

echo "   Memory usage test complete"

echo
echo "=== ANALYSIS OF RESULTS ==="

# Analyze startup performance
echo "STARTUP PERFORMANCE:"
if [ -f /tmp/startup_profile.log ]; then
    echo "  Top 5 slowest startup items:"
    sort -k2 -nr /tmp/startup_profile.log | head -5 | awk '{printf "    %s: %sms\n", $3, $2}'
fi

# Analyze stutter test results
echo
echo "STUTTER TEST RESULTS:"
if [ -f /tmp/stutter_output.log ]; then
    if grep -q "STUTTERING CONFIRMED" /tmp/stutter_output.log; then
        echo "  ❌ STUTTERING DETECTED"
        grep "STUTTER detected" /tmp/stutter_output.log | head -3
        grep "PROGRESSIVE SLOWDOWN" /tmp/stutter_output.log || echo "  No progressive slowdown detected"
    else
        echo "  ✅ No stuttering detected in systematic test"
    fi
fi

# Analyze function profiling
echo
echo "FUNCTION PROFILING:"
if [ -f /tmp/scroll_profile.log ]; then
    echo "  Top 5 most called functions during scrolling:"
    grep "^FUNCTION" /tmp/scroll_profile.log | sort -k4 -nr | head -5 | awk '{printf "    %s: %s calls, %s total time\n", $2, $4, $5}'

    echo "  Top 5 slowest functions:"
    grep "^FUNCTION" /tmp/scroll_profile.log | sort -k5 -nr | head -5 | awk '{printf "    %s: %s total time, %s calls\n", $2, $5, $4}'
fi

# Analyze memory progression
echo
echo "MEMORY USAGE:"
if [ -f /tmp/memory_progression.log ]; then
    echo "  Memory progression during scrolling:"
    grep "Memory" /tmp/memory_progression.log | tail -5

    # Check for memory leaks
    local mem_start=$(grep "Memory at start" /tmp/memory_progression.log | grep -o '[0-9]*\.[0-9]*' | head -1)
    local mem_end=$(grep "Memory after.*scrolls" /tmp/memory_progression.log | tail -1 | grep -o 'delta: [0-9\.-]*' | grep -o '[0-9\.-]*')

    if [ -n "$mem_end" ] && [ "$mem_end" != "0" ]; then
        echo "  ⚠️  Memory delta: ${mem_end} KB (potential memory leak)"
    else
        echo "  ✅ No significant memory leaks detected"
    fi
fi

echo
echo "=== RECOMMENDATIONS BASED ON PROFILING ==="

# Generate recommendations based on what we found
if [ -f /tmp/stutter_output.log ] && grep -q "STUTTERING CONFIRMED" /tmp/stutter_output.log; then
    echo "🔴 IMMEDIATE ACTION REQUIRED:"
    echo "  1. Stuttering confirmed - performance degradation detected"
    echo "  2. Check function profiling results in /tmp/scroll_profile.log"
    echo "  3. Look for high-frequency function calls during scrolling"
    echo "  4. Consider disabling expensive plugins during rapid movement"
fi

if [ -f /tmp/scroll_profile.log ]; then
    # Check for common performance culprits
    if grep -q "treesitter" /tmp/scroll_profile.log; then
        echo "🟡 Treesitter activity detected during scrolling"
        echo "  - Consider reducing treesitter update frequency"
    fi

    if grep -q "autocmd" /tmp/scroll_profile.log; then
        echo "🟡 Autocmd activity detected during scrolling"
        echo "  - Review autocmds for excessive cursor movement triggers"
    fi

    if grep -q "highlight\|syntax" /tmp/scroll_profile.log; then
        echo "🟡 Syntax highlighting activity detected"
        echo "  - Consider reducing syntax refresh frequency"
    fi
fi

echo
echo "=== FILES GENERATED ==="
echo "Profile files available for detailed analysis:"
echo "  - /tmp/startup_profile.log (startup performance)"
echo "  - /tmp/scroll_profile.log (function call profiling)"
echo "  - /tmp/stutter_output.log (systematic stutter test)"
echo "  - /tmp/memory_progression.log (memory usage)"
echo "  - /tmp/nvim_stutter_results.txt (detailed timing data)"

echo
echo "Run this script again to re-test after making performance improvements."
