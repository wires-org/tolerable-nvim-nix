-- see also pre-check.lua

if #vim.g._err > 0 then
	vim.call("writefile", vim.g._err, "stderr.txt")

	vim.cmd("cq 1")
end

vim.cmd("cq 0")
