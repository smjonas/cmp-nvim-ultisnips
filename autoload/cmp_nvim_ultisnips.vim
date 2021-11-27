" list[str]: Get the snippets that the user can expand, on the current line.
function! cmp_nvim_ultisnips#get_expandable_snippets()
pythonx << EOF
import vim
from UltiSnips import vim_helper

before = vim_helper.buf.line_till_cursor
snippets = UltiSnips_Manager._snips(before, True)
names = [snippet.trigger for snippet in snippets]
vim.command("let g:_expandable_snippets= {!r}".format(names))
EOF

return g:_expandable_snippets
endfunction
