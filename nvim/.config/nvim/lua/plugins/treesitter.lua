return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "tsx",
        "typescript",
        "javascript",
        "kotlin",
        "swift",
        "ruby",
        "markdown",
        "markdown_inline",
        "regex",
        "lua",
        "bash",
        "json",
        "yaml",
        "toml",
        "html",
        "css",
        "scss",
        "dockerfile",
        "embedded_template",
        "slim",
      })
    end,
  },
}
