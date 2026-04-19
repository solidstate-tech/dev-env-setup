return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "dockerfile",
        "ruby",
        "embedded_template",
        "slim",
        "scss",
      })
    end,
  },
}
