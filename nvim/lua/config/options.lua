-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true -- uses spaces instead of tab character
-- vim.opt.relativenumber = false
-- vim.opt.spell = true
-- vim.opt.spelllang = { "en_us", "cjk" }
vim.opt.spell = false

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp" },
    callback = function()
        vim.b.autoformat = false
    end,
})
