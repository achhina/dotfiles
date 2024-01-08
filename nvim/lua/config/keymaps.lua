local M = {}

function M.load_keymaps()
    -- [[ Basic Keymaps ]]

    -- Keymaps for better default experience
    -- See `:help vim.keymap.set()`
    vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

    -- Remap for dealing with word wrap
    vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
    vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

    -- Window splitting and management keymaps
    vim.keymap.set('n', '<leader>S', ':split<CR>', { noremap = true, silent = true})
    vim.keymap.set('n', '<leader>V', ':vsplit<CR>', { noremap = true, silent = true})
end

return M
