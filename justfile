# Run pre-commit hooks on all files
# Note: luacheck skipped (prek system hook limitation with --all-files)
check:
    prek run --all-files --skip luacheck
