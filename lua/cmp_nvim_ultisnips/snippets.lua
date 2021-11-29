local util = require('vim.lsp.util')
local parser = require('cmp_nvim_ultisnips.parser')

local snippets_info_for_file = {}

local function parse_ultisnips_snippets(snippets_filepath, file_contents)
  local cur_info
  local found_snippet_header = false

  for _, line in ipairs(file_contents) do
    if not found_snippet_header then
      local stripped_header = line:match('^%s*snippet%s+(.-)%s*$')
      -- Found possible snippet header
      if stripped_header then
        local header_info = parser.parse_snippet_header(stripped_header)
        if not vim.tbl_isempty(header_info) then
          cur_info = header_info
          cur_info.content = {}
          found_snippet_header = true
        end
      end
    elseif found_snippet_header and line:match('^endsnippet') ~= nil then
      cur_info.is_snipmate_snippet = false
      table.insert(snippets_info_for_file[snippets_filepath], cur_info)
      found_snippet_header = false
    elseif found_snippet_header then
      table.insert(cur_info.content, line)
    end
  end
  return snippets_info_for_file[snippets_filepath]
end

local function parse_snipmate_snippets(snippets_filepath, file_contents)
  local cur_info
  for _, line in ipairs(file_contents) do
    local stripped_header = line:match('^snippet!*%s+(.*)')
    if stripped_header then
      local trigger, description = stripped_header:match('^(%S+)%s+(.*)')
      if cur_info then
        -- Store the info for the previous snippet
        cur_info.is_snipmate_snippet = true
        table.insert(snippets_info_for_file[snippets_filepath], cur_info)
      end
      -- We need to create a new table
      cur_info = {
        tab_trigger = trigger,
        description = description,
        content = {}
      }
    elseif cur_info then  -- There was no header yet
      table.insert(cur_info.content, line)
    end
  end
  return snippets_info_for_file[snippets_filepath]
end

local function parse_snippets(snippets_filepath, do_parse_snipmate)
  local cur_info = snippets_info_for_file[snippets_filepath]
  if cur_info then
    return cur_info
  end
  snippets_info_for_file[snippets_filepath] = {}
  local file_contents = vim.fn.readfile(snippets_filepath)
  if do_parse_snipmate then
    return parse_snipmate_snippets(snippets_filepath, file_contents)
  else
    return parse_ultisnips_snippets(snippets_filepath, file_contents)
  end
end

local M = {}

-- Stores all parsed snippet information for a particular file type
local snippet_info_for_ft = {}

function M.load_snippet_info()
  local ft = vim.bo.filetype
  local snippets_info = snippet_info_for_ft[ft]
  if snippets_info == nil then
    snippets_info = {}
    vim.F.npcall(vim.call, 'UltiSnips#SnippetsInCurrentScope', 1)

    local visited_filepath = {}
    for _, info in pairs(vim.g.current_ulti_dict_info) do
      local filepath = info.location:gsub('%.snippets:%d*$', '.snippets')
      if not visited_filepath[filepath] then
        local innermost_folder = filepath:match('^.*/(.+)/.*%.snippets$')
        -- If false, the folder contains snippets that use UltiSnips syntax
        local is_snipmate_folder = innermost_folder == 'snippets'
        local result = parse_snippets(filepath, is_snipmate_folder)
        table.insert(snippets_info, result)
        visited_filepath[filepath] = true
      end
    end
  end
  return snippets_info
end

function M.clear_caches()
  snippets_info_for_file = {}
  snippet_info_for_ft = {}
end

function M.format_snippet_content(content)
  local snippet_content = {}

  table.insert(snippet_content, '```' .. vim.bo.filetype)
  for _, line in ipairs(content) do
    table.insert(snippet_content, line)
  end
  table.insert(snippet_content, '```')

  local snippet_docs = util.convert_input_to_markdown_lines(snippet_content)
  return table.concat(snippet_docs, '\n')
end

-- Returns the documentation string shown by cmp
function M.documentation(snippet_info)
  local description = ''
  if snippet_info.description then
    -- Italicize description
    description = '*' .. snippet_info.description ..  '*'
  end
  local header = description .. '\n\n'
  return header .. M.format_snippet_content(snippet_info.content)
end

return M
