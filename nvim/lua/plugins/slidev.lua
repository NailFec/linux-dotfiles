return {
    {
        "mei28/slidev.nvim",
        config = function()
            require("slidev").setup({
                -- Optional configuration (default values)
                port = 3030,
                auto_open_browser = true,
                debug = false,
            })
        end,
    },
}
