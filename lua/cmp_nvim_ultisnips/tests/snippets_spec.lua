local snippets = require('cmp_nvim_ultisnips.snippets')

describe('snippets', function()
    it('should handle regex tab-trigger with ? quantifier', function()
      local tab_trigger = 'ab?c'
      assert.are_same('ac', snippets.handle_regex_trigger(tab_trigger, 'shortest'))
      assert.are_same('abc', snippets.handle_regex_trigger(tab_trigger, 'longest'))
    end)

    it('should handle regex tab-trigger with * quantifier', function()
      local tab_trigger = 'ab*c'
      assert.are_same('ac', snippets.handle_regex_trigger(tab_trigger, 'shortest'))
      assert.are_same('abc', snippets.handle_regex_trigger(tab_trigger, 'longest'))
    end)

    it('should not handle regex tab-trigger with capture group', function()
      local tab_trigger = 'a(b|B)?c'
      assert.are_same(nil, snippets.handle_regex_trigger(tab_trigger, 'shortest'))
    end)
end)
