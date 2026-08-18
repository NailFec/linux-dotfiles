return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                nim_langserver = {
                    flags = {
                        debounce_text_changes = 1000,
                    },
                    settings = {
                        nim = {
                            timeout = 60000,
                            autoCheckFile = true,
                            nimsuggestTimeout = 60000,
                            maxNimsuggestProcesses = 1,
                            autoRestart = true,
                        },
                    },
                },
            },
        },
    },
}
