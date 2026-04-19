return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {},
        eslint = {},
        bashls = {},
        jsonls = {},
        yamlls = {},
        taplo = {},
        marksman = {},
        dockerls = {},
        docker_compose_language_service = {},
        ruby_lsp = {},
        kotlin_language_server = {},
        sourcekit = {},   -- iOS Swift; binary installed by Xcode, not Mason
        gopls = {},
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "vtsls",
        "eslint-lsp",
        "bash-language-server",
        "json-lsp",
        "yaml-language-server",
        "taplo",
        "marksman",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "ruby-lsp",
        "kotlin-language-server",
        "gopls",
      })
    end,
  },
}
