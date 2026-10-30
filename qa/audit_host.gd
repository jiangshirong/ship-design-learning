extends "res://main.gd"
func run_qa()->void:
 if "--minimum" in OS.get_cmdline_user_args():get_window().size=Vector2i(1100,760)
 var suite=load("res://qa/audit_focus_check.gd" if "--audit-focus" in OS.get_cmdline_user_args() else "res://qa/audit_original_check.gd").new();add_child(suite);suite.start(self)
