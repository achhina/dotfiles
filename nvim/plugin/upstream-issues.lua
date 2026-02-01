-- Upstream issue tracking via check-upstream-issues CLI
-- Displays diagnostics for @upstream-issue tags
-- Auto-loaded on startup via plugin/ directory

-- Cache: filepath -> {issues: table, timestamp: number}
local cache = {}
local CACHE_TTL = 3600 -- 1 hour

-- Diagnostic namespace
local ns = vim.api.nvim_create_namespace("upstream-issues")

---Check if cached result is still valid
local function is_cache_valid(filepath)
  local cached = cache[filepath]
  if not cached then
    return false
  end
  return (os.time() - cached.timestamp) < CACHE_TTL
end

---Set diagnostics for a buffer
local function set_diagnostics(bufnr, data)
  if not data or (not data.resolved and not data.open) then
    return
  end

  local diagnostics = {}
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Resolved issues (can be removed)
  for _, issue in ipairs(data.resolved or {}) do
    for _, loc in ipairs(issue.locations or {}) do
      if vim.endswith(filepath, loc.file) or vim.endswith(loc.file, vim.fn.expand("%:t")) then
        table.insert(diagnostics, {
          lnum = loc.line - 1,
          col = 0,
          end_col = -1,
          severity = vim.diagnostic.severity.WARN,
          message = string.format(
            "✓ %s/%s#%d resolved - workaround can be removed",
            issue.org,
            issue.repo,
            issue.number
          ),
          source = "upstream-issues",
          user_data = {
            issue_url = issue.url,
            closed_at = issue.closed_at,
            title = issue.title,
          },
        })
      end
    end
  end

  -- Open issues (keep workaround)
  for _, issue in ipairs(data.open or {}) do
    for _, loc in ipairs(issue.locations or {}) do
      if vim.endswith(filepath, loc.file) or vim.endswith(loc.file, vim.fn.expand("%:t")) then
        table.insert(diagnostics, {
          lnum = loc.line - 1,
          col = 0,
          end_col = -1,
          severity = vim.diagnostic.severity.INFO,
          message = string.format(
            "○ %s/%s#%d still open - workaround needed",
            issue.org,
            issue.repo,
            issue.number
          ),
          source = "upstream-issues",
          user_data = {
            issue_url = issue.url,
            title = issue.title,
          },
        })
      end
    end
  end

  -- Set diagnostics
  vim.diagnostic.set(ns, bufnr, diagnostics, {
    virtual_text = {
      prefix = "",
      spacing = 2,
    },
    signs = true,
    underline = false,
    update_in_insert = false,
  })
end

---Check upstream issues for a buffer (non-blocking)
local function check_buffer(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" or vim.fn.filereadable(filepath) == 0 then
    return
  end

  -- Use cache if valid
  if is_cache_valid(filepath) then
    set_diagnostics(bufnr, cache[filepath].issues)
    return
  end

  -- Get directory containing the file
  local dir = vim.fn.fnamemodify(filepath, ":h")

  -- Run check-upstream-issues asynchronously
  vim.system({ "check-upstream-issues", dir, "--json" }, {
    text = true,
    cwd = dir,
  }, vim.schedule_wrap(function(obj)
    if obj.code == 0 and obj.stdout then
      local ok, data = pcall(vim.json.decode, obj.stdout)

      if ok and data then
        -- Cache result
        cache[filepath] = {
          issues = data,
          timestamp = os.time(),
        }

        -- Set diagnostics
        set_diagnostics(bufnr, data)
      end
    end
  end))
end

-- Setup autocmds
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("UpstreamIssues", { clear = true }),
  callback = function(args)
    check_buffer(args.buf)
  end,
  desc = "Check upstream issues in buffer",
})

-- Commands
vim.api.nvim_create_user_command("UpstreamIssuesCheck", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  cache[filepath] = nil
  check_buffer(bufnr)
end, {
  desc = "Check upstream issues for current buffer",
})

vim.api.nvim_create_user_command("UpstreamIssuesClearCache", function()
  cache = {}
  vim.notify("Upstream issues cache cleared", vim.log.levels.INFO)
end, {
  desc = "Clear upstream issues cache",
})
