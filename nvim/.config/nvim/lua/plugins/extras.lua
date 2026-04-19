return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },
  {
    "nvim-pack/nvim-spectre",
    cmd = "Spectre",
    keys = {
      { "<leader>sR", function() require("spectre").open() end, desc = "Spectre (project find/replace)" },
    },
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },
}
