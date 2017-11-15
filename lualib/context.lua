local context = {
	init_flag = false,
}

function context:init(cfg_data)
	self.cfg_data = cfg_data
	self.init_flag = true
end

function context:get_cfg_data()
	return self.cfg_data
end

return context
