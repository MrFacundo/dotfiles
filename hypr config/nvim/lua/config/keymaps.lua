-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Save file with Ctrl+S
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Toggle tree focus with Ctrl + 1
vim.keymap.set("n", "<C-1>", function()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local ft = vim.bo[buf].filetype

  if ft == "neo-tree" then
    vim.cmd("wincmd p")
  else
    vim.cmd("Neotree focus")
  end
end, { desc = "Toggle focus between Neo-tree and editor" })
