return {
    {
        "bjarneo/aether.nvim",
        branch = "v2",
        name = "aether",
        priority = 1000,
        opts = {
            transparent = false,
            colors = {
                -- Background colors
                bg = "#06080e",
                bg_dark = "#06080e",
                bg_highlight = "#647096",

                -- Foreground colors
                -- fg: Object properties, builtin types, builtin variables, member access, default text
                fg = "#ffffff",
                -- fg_dark: Inactive elements, statusline, secondary text
                fg_dark = "#e7ebeb",
                -- comment: Line highlight, gutter elements, disabled states
                comment = "#647096",

                -- Accent colors
                -- red: Errors, diagnostics, tags, deletions, breakpoints
                red = "#de4a4a",
                -- orange: Constants, numbers, current line number, git modifications
                orange = "#f09393",
                -- yellow: Types, classes, constructors, warnings, numbers, booleans
                yellow = "#f4b752",
                -- green: Comments, strings, success states, git additions
                green = "#41e0f6",
                -- cyan: Parameters, regex, preprocessor, hints, properties
                cyan = "#7fdbf6",
                -- blue: Functions, keywords, directories, links, info diagnostics
                blue = "#8e9fc7",
                -- purple: Storage keywords, special keywords, identifiers, namespaces
                purple = "#bbb9bb",
                -- magenta: Function declarations, exception handling, tags
                magenta = "#e8e8e8",
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
