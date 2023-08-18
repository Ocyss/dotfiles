return {
    {   -- 底部信息栏
        "akinsho/bufferline.nvim",
        config = true, 
    },
    {   -- 标签页
        "lukas-reineke/indent-blankline.nvim",
        config = true,
    },
    {   -- Git 左侧竖线
        "lewis6991/gitsigns.nvim",
        config = true,
    },
    {   -- 启动页
        "goolord/alpha-nvim",
        config = function()
            require'alpha'.setup(require'alpha.themes.dashboard'.config)
        end
    },
    {   -- 相同词语高亮
        "RRethy/vim-illuminate",
        config = function()
            require('illuminate').configure()
        end
    },
}
