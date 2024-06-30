-- checks for any error notifications
-- see also post-check.lua

-- TODO: Update to include v:errmsg somehow...

vim.g._err = {}

vim.notify = function(msg, level)
	local tbl = vim.g._err

	if level == vim.log.levels.ERROR then
		table.insert(tbl, msg)
		vim.g._err = tbl
	end
end
