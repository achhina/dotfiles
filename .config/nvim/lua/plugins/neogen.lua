return {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,
    opts = {
        snippet_engine = "luasnip",
        languages = {
            python = {
                template = {
                    annotation_convention = "numpydoc"
                }
            }
        }
    },
    -- Follow stable versions only
    version = "*"
}
