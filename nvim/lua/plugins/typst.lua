return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                tinymist = {
                    settings = {
                        formatterMode = "typstyle",
                        formatterPrintWidth = 80,
                        formatterProseWrap = "sentence", -- none | fill | sentence
                        exportPdf = "onSave", -- onType | onSave
                        semanticTokens = "enable",
                    },
                },
            },
        },
    },
    {
        "chomosuke/typst-preview.nvim",
        ft = "typst",
        version = "1.*",
        opts = {
            follow_cursor = true,
            partial_rendering = true, -- 大文档只渲可见部分，v1.5 起默认开
            -- invert_colors = "never", -- 暗色浏览器会把页面反色，写稿时建议 never
            dependencies_bin = { tinymist = "tinymist" },
            -- Niri / Wayland：指定浏览器，避免 xdg-open 开错
            -- open_cmd = "qutebrowser --target window %s",
            -- open_cmd = "firefox --new-window %s",
            -- open_cmd = "firefox --profile " .. vim.fn.expand("~/.mozilla/firefox/xxxx.typst") .. " --new-window %s",
            open_cmd = "zen-browser --new-window %s",
            -- get_main_file = function(path) return vim.fn.getcwd() .. "/main.typ" end,
        },
        keys = {
            { "<leader>tp", "<cmd>TypstPreviewToggle<cr>", desc = "Typst 预览开关", ft = "typst" },
            { "<leader>ts", "<cmd>TypstPreviewSyncCursor<cr>", desc = "预览跳到光标", ft = "typst" },
            { "<leader>tf", "<cmd>TypstPreviewFollowCursor<cr>", desc = "预览跟随光标", ft = "typst" },
            { "<leader>tF", "<cmd>TypstPreviewNoFollowCursor<cr>", desc = "停止跟随", ft = "typst" },
        },
    },
}
