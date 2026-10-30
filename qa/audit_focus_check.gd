extends "res://qa/formal_check.gd"
func signal_targets(field:Control)->Array:
 var found:Array=[]
 for connection in field.gui_input.get_connections():found.append(str(connection.callable.get_method()))
 return found
func start(target)->void:
 app=target
 var findings:Dictionary={"window":str(app.get_window().size),"user_data_dir":OS.get_user_data_dir()}
 await app.open_course("basics","");await settle()
 if app.lang!="ru":app.toggle_language()
 await frames(5)
 findings.homework={"id":app.beat.id,"text":app.caption.text,"input_handlers":signal_targets(app.caption),"tooltip_created":is_instance_valid(app.review.term_tooltip)}
 app.go_home();await app.open_course("bulkheads","");await frames(14)
 findings.bulkheads={"input_handlers":signal_targets(app.bulkheads.speech.caption),"tooltip_created":is_instance_valid(app.review.term_tooltip)}
 app.go_home();await frames(5)
 await app.open_course("approximation3","AP3:standard_chart");await settle()
 if app.lang!="zh":app.toggle_language()
 app.toggle_language();await frames(15)
 var record=app.equations.entries["AP3:standard_chart"].box
 findings.ap3={"record_rect":str(record.get_global_rect()),"scroll_rect":str(app.right_scroll.get_global_rect()),"visible_intersection":record.get_global_rect().intersects(app.right_scroll.get_global_rect()),"scroll":app.right_scroll.scroll_vertical}
 app.get_viewport().get_texture().get_image().save_png("res://qa/audit-20261023/ap3-standard-chart-minimum.png")
 var glossary=preload("res://modules/review/core/glossary.gd").new()
 findings.lookup={}
 for word in ["недоста́точная","ме́ньшей","су́дно","определи́ть"]:
  var matches:Array=glossary.spans(word);var names:Array=[]
  for m in matches:names.append(m.entry.ru)
  findings.lookup[word]=names
 var report=FileAccess.open("res://qa/audit-20261023/focused.json",FileAccess.WRITE)
 report.store_string(JSON.stringify(findings,"\t"));report.close()
 print("FOCUSED AUDIT ",JSON.stringify(findings));get_tree().quit()
