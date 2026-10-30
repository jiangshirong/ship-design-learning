extends "res://qa/merge_check.gd"
func start(target)->void:
	host=target;app=host.review
	await migration_checks()
	var failed:int=results.filter(func(r):return not r.passed).size()
	var file=FileAccess.open("res://qa/repair-20261023/migration-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"  "));file.close()
	print("MIGRATION ",results.size()," checks; failures ",failed)
	get_tree().quit(1 if failed else 0)
