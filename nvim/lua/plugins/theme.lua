return {
    {
        "navarasu/onedark.nvim",
        dependencies = {
            "nvim-lualine/lualine.nvim",
            "nvim-tree/nvim-web-devicons",
            "utilyre/barbecue.nvim",
            "SmiteshP/nvim-navic",
        },
        config = function()
            require('onedark').setup {
                style = 'darker'
            }
            require('onedark').load()
            require('lualine').setup({
                options = {
                    theme = 'onedark',
                },
            })
            require('barbecue').setup {
                theme = 'onedark',
            }
        end
    },
}

