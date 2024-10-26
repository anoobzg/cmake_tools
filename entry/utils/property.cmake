macro(__append_global_property property value)
	get_property(TVALUES GLOBAL PROPERTY ${property})
	set_property(GLOBAL PROPERTY ${property} ${TVALUES} ${value}) 
endmacro()