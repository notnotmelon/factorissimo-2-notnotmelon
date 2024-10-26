Updates = {}

Updates.init = function()
	storage.update_version = 2
end

local function fix_common_issues()

end

Updates.run = function()
	fix_common_issues()
end
