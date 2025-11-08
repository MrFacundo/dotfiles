return {
  {
    "daschw/leaf.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("leaf").setup({
        underlineStyle = "underline",
        commentStyle = "italic",
        functionStyle = "NONE",
        keywordStyle = "italic",
        statementStyle = "bold",
        typeStyle = "NONE",
        variablebuiltinStyle = "italic",
        transparent = false,
        colors = {},
        overrides = {},
        theme = "auto", -- "auto" uses vim.o.background, or set to "light" or "dark"
        contrast = "low", -- options: "low", "medium", "high"
      })
      vim.cmd("colorscheme leaf")
    end,
  },
}
