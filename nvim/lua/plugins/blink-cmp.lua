return {
    {
        "saghen/blink.cmp",
        opts = {
            keymap = {
                preset = "enter",
                -- 回车只换行，不再确认补全
                ["<CR>"] = { "fallback" },
                -- Tab 确认当前项；没选中时确认第一项；没有菜单时继续跳 snippet / 缩进
                ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            },
        },
    },
}
