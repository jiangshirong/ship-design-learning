extends RefCounted

static var cache:Dictionary={}
static func icon(kind:String)->Texture2D:
	if cache.has(kind):return cache[kind]
	var color:String={"known":"#a8dbc1","review":"#efc477","":"#8da8b5","sidebar":"#dce7ee"}[kind]
	var shape:String={
		"known":'<circle cx="12" cy="12" r="9"/><path d="m7.5 12 3 3 6-6"/>',
		"review":'<path d="M4 10a8 8 0 1 1 1 7M4 4v6h6"/>',
		"":'<circle cx="12" cy="12" r="7"/>',
		"sidebar":'<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M9 4v16m4-11h5m-5 6h5"/>'
	}[kind]
	var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="%s" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>'%[color,shape]
	cache[kind]=DPITexture.create_from_string(svg,1.0)
	return cache[kind]
