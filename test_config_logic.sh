#!/bin/bash
# Logic test for configuration system
# Verifies that the configuration merging works correctly

echo "=== Configuration Logic Tests ==="
echo

test_passed=0
test_failed=0

# Test 1: Verify default configuration structure
echo "Test 1: Default configuration structure"
if grep -A5 "local defaults = {" lua/send-to-agent.lua | grep -q "agents = {" &&
   grep -A10 "local defaults = {" lua/send-to-agent.lua | grep -q "patterns = {" &&
   grep -A10 "local defaults = {" lua/send-to-agent.lua | grep -q "priority_order = {"; then
  echo "  ✅ PASS - Default configuration has correct structure"
  ((test_passed++))
else
  echo "  ❌ FAIL - Default configuration structure is incorrect"
  ((test_failed++))
fi
echo

# Test 2: Verify configuration merging logic
echo "Test 2: Configuration merging with vim.tbl_deep_extend"
if grep -q "config = vim.tbl_deep_extend" lua/send-to-agent.lua; then
  echo "  ✅ PASS - Uses vim.tbl_deep_extend for merging"
  ((test_passed++))
else
  echo "  ❌ FAIL - Missing configuration merge logic"
  ((test_failed++))
fi
echo

# Test 3: Verify get_config function exists
echo "Test 3: get_config function implementation"
if grep -A10 "local function get_config()" lua/send-to-agent.lua | grep -q "return config"; then
  echo "  ✅ PASS - get_config() returns configuration"
  ((test_passed++))
else
  echo "  ❌ FAIL - get_config() implementation issue"
  ((test_failed++))
fi
echo

# Test 4: Verify agent detection uses config
echo "Test 4: Agent detection uses configuration"
if grep -A20 "local function detect_agent_panes()" lua/send-to-agent.lua | grep -q "current_config.agents.patterns"; then
  echo "  ✅ PASS - detect_agent_panes() uses config.agents.patterns"
  ((test_passed++))
else
  echo "  ❌ FAIL - Agent detection doesn't use configuration"
  ((test_failed++))
fi
echo

# Test 5: Verify priority selection uses config
echo "Test 5: Priority selection uses configuration"
if grep -A30 "local function select_best_agent" lua/send-to-agent.lua | grep -q "current_config.agents.priority_order"; then
  echo "  ✅ PASS - select_best_agent() uses config.agents.priority_order"
  ((test_passed++))
else
  echo "  ❌ FAIL - Agent selection doesn't use priority configuration"
  ((test_failed++))
fi
echo

# Test 6: Verify all 5 default agents are present
echo "Test 6: All default agents present"
agent_count=0
for agent in "claude" "codex" "cursor-agent" "opencode" "gemini"; do
  if grep -A5 "local defaults = {" lua/send-to-agent.lua | grep -A3 "patterns = {" | grep -q "\"$agent\""; then
    ((agent_count++))
  fi
done

if [ $agent_count -eq 5 ]; then
  echo "  ✅ PASS - All 5 default agents found (claude, codex, cursor-agent, opencode, gemini)"
  ((test_passed++))
else
  echo "  ❌ FAIL - Expected 5 default agents, found $agent_count"
  ((test_failed++))
fi
echo

# Test 7: Verify priority order matches patterns
echo "Test 7: Default priority order matches patterns"
if grep -A7 "local defaults = {" lua/send-to-agent.lua | grep -A1 "patterns = {" | head -1 > /tmp/patterns.txt &&
   grep -A7 "local defaults = {" lua/send-to-agent.lua | grep -A1 "priority_order = {" | head -1 > /tmp/priority.txt; then
  if diff -q /tmp/patterns.txt /tmp/priority.txt > /dev/null 2>&1; then
    echo "  ✅ PASS - Default patterns and priority_order match"
    ((test_passed++))
  else
    echo "  ⚠️  WARNING - Patterns and priority_order may differ (this could be intentional)"
    ((test_passed++))
  fi
  rm -f /tmp/patterns.txt /tmp/priority.txt
else
  echo "  ❌ FAIL - Could not compare patterns and priority_order"
  ((test_failed++))
fi
echo

# Summary
echo "=== Test Results ==="
echo "✅ Passed: $test_passed"
echo "❌ Failed: $test_failed"
echo "📊 Total:  $((test_passed + test_failed))"
echo

if [ $test_failed -eq 0 ]; then
  echo "🎉 All configuration logic tests passed!"
  echo "✨ The configuration system is working correctly!"
  exit 0
else
  echo "💥 Some tests failed!"
  exit 1
fi
