local cmpu_source = require('cmp_nvim_ultisnips.source')
local cmpu_snippets = require('cmp_nvim_ultisnips.snippets')

local M = {}

local default_config = {
  show_snippets = 'expandable_or_regex',
  regex_snippets = {
    enable = true,
    completion_strategy = 'shortest'
  },
  documentation = cmpu_snippets.documentation
}

local user_config = default_config
function M.setup(config)
  user_config = vim.tbl_deep_extend('force', default_config, config)
  vim.validate({
    show_snippets = {
      user_config.show_snippets,
      function(arg)
        return arg == 'expandable' or arg == 'expandable_or_regex' or arg == 'all'
      end,
      "either 'expandable' or 'expandable_or_regex' or 'all'"
    },
    regex_snippets = {
      user_config.regex_snippets,
      function(regex_arg)
        if type(regex_arg) == 'table' then
          vim.validate({
            enable = { regex_arg.enable, 'boolean' },
            completion_strategy = {
              regex_arg.completion_strategy,
              function(arg)
                return arg == 'shortest' or arg == 'longest'
              end,
              "either 'shortest' or 'longest'"
            }
          })
          return true
        end
        return false
      end,
      'a table'
    },
    documentation = { user_config.documentation, 'function' }
  })
  if user_config.regex_snippets and user_config.show_snippets == 'expandable' then
    vim.notify(
      "[cmp-nvim-ultisnips] There are some issues with your config:\nregex_snippets = true " ..
      "has no effect when show_snippets is set to 'expandable'. Use show_snippets = " ..
      "'expandable_or_regex' instead or set regex_snippets to false.", vim.log.levels.WARN
    )
  end
end

function M.create_source()
  return cmpu_source.new(user_config)
end

return M
