local cmp = require('cmp')
local cmpu_snippets = require('cmp_nvim_ultisnips.snippets')

local source = {}
function source.new(config)
  local self = setmetatable({}, { __index = source })
  self.config = config
  return self
end

function source:get_keyword_pattern()
  return '\\%([^[:alnum:][:blank:]]\\|\\w\\+\\)'
end

function source:get_debug_name()
  return 'ultisnips'
end

function source.complete(self, _, callback)
  local items = {}
  local info = cmpu_snippets.load_snippet_info()
  local expandable_snippets
  for _, snippet_info in pairs(info) do

    local show_snippets = self.config.show_snippets
    local is_regex_snippet = snippet_info.options and snippet_info.options:match('r')
    local skip = is_regex_snippet and not self.config.regex_snippets.enable
      -- regex snippets are never returned by UltiSnips, thus not expandable
      or is_regex_snippet and show_snippets == 'expandable'

    if not skip then
      if show_snippets == 'expandable' or (show_snippets == 'expandable_or_regex' and not is_regex_snippet) then
        if not expandable_snippets then
          expandable_snippets = vim.fn["cmp_nvim_ultisnips#get_expandable_snippets"]()
        end
        skip = not vim.tbl_contains(expandable_snippets, snippet_info.tab_trigger)
      end
    end

    if not skip then
      local handled_regex_trigger
      if is_regex_snippet then
        local strategy = self.config.regex_snippets.completion_strategy
        handled_regex_trigger = cmpu_snippets.handle_regex_trigger(snippet_info.tab_trigger, strategy)
      end
      if not is_regex_snippet or handled_regex_trigger then
        local item = {
          -- TODO: change label to modified_tab_trigger
          word =  handled_regex_trigger,
          label = snippet_info.tab_trigger,
          kind = cmp.lsp.CompletionItemKind.Snippet,
          userdata = snippet_info,
        }
        table.insert(items, item)
      end
    end
  end
  callback(items)
end

function source.resolve(self, completion_item, callback)
  local doc_string = self.config.documentation(completion_item.userdata)
  if doc_string ~= nil then
    completion_item.documentation = {
      kind = cmp.lsp.MarkupKind.Markdown,
      value = doc_string
    }
  end
  callback(completion_item)
end

function source:execute(completion_item, callback)
  vim.call('UltiSnips#ExpandSnippet')
  callback(completion_item)
end

function source:is_available()
  -- if UltiSnips is installed then this variable should be defined
  return vim.g.UltiSnipsExpandTrigger ~= nil
end

return source
