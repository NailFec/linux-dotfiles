return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                nim_langserver = {
                    -- 因为你是用 nimble 安装的，不是 mason，所以关掉 mason 自动安装
                    mason = false,
                    -- 如果需要自定义设置可以加这里
                    -- settings = {
                    --   nim = {
                    --     -- nimsuggestPath = "...",
                    --   },
                    -- },
                },
            },
        },
    },
}
