local plugins = {
    {"nvim-tree/nvim-tree.lua", 
     lazy = false,
     opts={
      filters={dotfiles=false}
    }
  }, {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = {
                "c_sharp", "haskell", "kotlin", "swift", "typescript", "python", "go"
            }
        }
    }, {
        "neovim/nvim-lspconfig",
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
        end
    }, {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                "prettier", "haskell-language-server", "csharp-language-server",
                "typescript-language-server", "html-lsp", "gopls"
            }
        }
    }, {
        "epwalsh/obsidian.nvim",
        lazy = true,
        event = {"BufReadPre " .. vim.fn.expand "~" .. "/obsidian-vault/**.md"},
        dependencies = {
            "nvim-lua/plenary.nvim", "hrsh7th/nvim-cmp",
            "nvim-telescope/telescope.nvim", "preservim/vim-markdown"
        },
        opts = {
            dir = "~/obsidian-vault",

            completion = {min_chars = 2, new_notes_location = "current_dir"},

            open_app_foreground = true,
            finder = "telescope.nvim"
        },
        config = function(_, opts) require("obsidian").setup(opts) end
    }, {
      "github/copilot.vim",
      lazy=false
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy=false
  },
{
  "olexsmir/gopher.nvim",
  config = function()
    require("gopher").setup()
  end,
  event = { "BufReadPre *.go" },
  ft = {"go", 'gomod'},
  build = function()
    vim.cmd [[silent! GoInstallDeps]]
  end 

}
}

return plugins
