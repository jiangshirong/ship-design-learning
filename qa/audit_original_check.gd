extends "res://qa/formal_check.gd"
func tap(code:int)->void:
 super.tap(KEY_E if code==KEY_D else (KEY_Q if code==KEY_A else code))
