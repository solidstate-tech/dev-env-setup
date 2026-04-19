return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "biome", "prettierd", stop_after_first = true },
        typescript = { "biome", "prettierd", stop_after_first = true },
        javascriptreact = { "biome", "prettierd", stop_after_first = true },
        typescriptreact = { "biome", "prettierd", stop_after_first = true },
        json = { "biome", "prettierd", stop_after_first = true },
        jsonc = { "biome", "prettierd", stop_after_first = true },
        yaml = { "prettierd" },
        markdown = { "prettierd" },
        lua = { "stylua" },
        ruby = { "rubocop" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        kotlin = { "ktlint" },
        swift = { "swiftformat" },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
          return
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "biome",
        "prettierd",
        "stylua",
        "rubocop",
        "shfmt",
        "shellcheck",
        "ktlint",
      })
    end,
  },
}
