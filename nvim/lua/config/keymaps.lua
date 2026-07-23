vim.notify("keymaps.lua loaded!")
local Terminal = require("toggleterm.terminal").Terminal

local function get_latest_input(dir, base)
    local files = vim.fn.globpath(dir, base .. "*.txt", false, true)
    local max_n, max_file = -1, nil
    for _, f in ipairs(files) do
        local name = vim.fn.fnamemodify(f, ":t")
        local n = name:match("^" .. base .. "(%d+)%.txt$")
        if n then
            n = tonumber(n)
            if n > max_n then
                max_n = n
                max_file = f
            end
        end
    end
    return max_file
end

local opts = { buffer = true, silent = true }

local CFLAGS = "-std=c++17 -O2 -Wall -Wextra -Wshadow -DLOCAL "
    .. "-fsanitize=address,undefined -fno-sanitize-recover=all"

-- F5: Compile only
vim.keymap.set("n", "<F5>", function()
    vim.cmd("write")
    local file = vim.fn.expand("%:p")
    local out = vim.fn.expand("%:p:r")
    local cmd = string.format("g++ %s -o %s %s", CFLAGS, out, file)
    Terminal:new({ cmd = cmd, direction = "horizontal", close_on_exit = false }):toggle()
end, vim.tbl_extend("force", opts, { desc = "Compile C++" }))

-- F6: Compile + run interactively
vim.keymap.set("n", "<F6>", function()
    vim.cmd("write")
    local file = vim.fn.expand("%:p")
    local out = vim.fn.expand("%:p:r")
    local cmd = string.format("g++ %s -o %s %s && %s", CFLAGS, out, file, out)
    Terminal:new({ cmd = cmd, direction = "horizontal", close_on_exit = false }):toggle()
end, vim.tbl_extend("force", opts, { desc = "Compile & Run (interactive stdin)" }))

-- F7: Compile + run against latest test file
vim.keymap.set("n", "<F7>", function()
    vim.cmd("write")
    local dir = vim.fn.expand("%:p:h")
    local file = vim.fn.expand("%:p")
    local out = vim.fn.expand("%:p:r")
    local base = vim.fn.expand("%:t:r")

    local input_file = get_latest_input(dir, base)

    local cmd
    if input_file then
        cmd = string.format(
            "g++ %s -o %s %s && echo '--- using %s ---' && %s < %s",
            CFLAGS,
            out,
            file,
            vim.fn.fnamemodify(input_file, ":t"),
            out,
            input_file
        )
    else
        cmd = string.format(
            "g++ %s -o %s %s && echo '--- no input file found, running raw ---' && %s",
            CFLAGS,
            out,
            file,
            out
        )
    end

    Terminal:new({ cmd = cmd, direction = "horizontal", close_on_exit = false }):toggle()
end, vim.tbl_extend("force", opts, { desc = "Compile & Run (latest test file)" }))

-- F8: Open latest test file
vim.keymap.set("n", "<F8>", function()
    local dir = vim.fn.expand("%:p:h")
    local base = vim.fn.expand("%:t:r")
    local latest = get_latest_input(dir, base) or (dir .. "/" .. base .. "1.txt")
    vim.cmd("vsplit " .. latest)
end, vim.tbl_extend("force", opts, { desc = "Open latest test file" }))

-- F9: Create next numbered test file
vim.keymap.set("n", "<F9>", function()
    local dir = vim.fn.expand("%:p:h")
    local base = vim.fn.expand("%:t:r")
    local latest = get_latest_input(dir, base)
    local next_n = 1
    if latest then
        local n = vim.fn.fnamemodify(latest, ":t"):match("^" .. base .. "(%d+)%.txt$")
        next_n = tonumber(n) + 1
    end
    vim.cmd("vsplit " .. dir .. "/" .. base .. next_n .. ".txt")
end, vim.tbl_extend("force", opts, { desc = "New test file (auto-numbered)" }))
