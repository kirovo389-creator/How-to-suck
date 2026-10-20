extends CanvasLayer
signal action_pressed
signal movement_changed(direction: Vector2)
signal call_answered
var status_label: Label
var task_label: Label
var toast_label: Label
var intro_panel: PanelContainer
var call_panel: PanelContainer
var ending_panel: PanelContainer
var move_vec := Vector2.ZERO
var touch_index := -1

func _ready():
    var root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)
    var panel = PanelContainer.new()
    panel.position = Vector2(18,18)
    panel.custom_minimum_size = Vector2(410,100)
    _style(panel,Color(0.025,0.04,0.07,0.9))
    root.add_child(panel)
    var col = VBoxContainer.new()
    panel.add_child(col)
    var title = Label.new()
    title.text = "HOW TO SUCK  •  NIGHT SHIFT"
    title.add_theme_font_size_override("font_size",20)
    title.add_theme_color_override("font_color",Color(0.52,0.88,0.95))
    col.add_child(title)
    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size",17)
    col.add_child(status_label)
    task_label = Label.new()
    task_label.add_theme_font_size_override("font_size",16)
    task_label.add_theme_color_override("font_color",Color(0.96,0.76,0.42))
    col.add_child(task_label)
    toast_label = Label.new()
    toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    toast_label.position = Vector2(-250,24)
    toast_label.custom_minimum_size = Vector2(500,40)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size",21)
    toast_label.add_theme_color_override("font_color",Color(1,0.9,0.65))
    root.add_child(toast_label)
    var joy = Control.new()
    joy.position = Vector2(30,490)
    joy.custom_minimum_size = Vector2(165,165)
    joy.mouse_filter = Control.MOUSE_FILTER_STOP
    joy.draw.connect(func():
        joy.draw_circle(Vector2(82,82),74,Color(0.12,0.2,0.27,0.62))
        joy.draw_arc(Vector2(82,82),74,0,TAU,48,Color(0.5,0.8,0.9,0.8),3)
        joy.draw_circle(Vector2(82+move_vec.x*43,82+move_vec.y*43),28,Color(0.35,0.68,0.76,0.9))
    )
    joy.gui_input.connect(_joy_input.bind(joy))
    root.add_child(joy)
    var hint = Label.new()
    hint.text = "ДВИЖЕНИЕ"
    hint.position = Vector2(55,655)
    hint.add_theme_color_override("font_color",Color(0.8,0.9,1,0.8))
    root.add_child(hint)
    var act = Button.new()
    act.text = "ВЗЯТЬ / МЫТЬ"
    act.position = Vector2(1010,565)
    act.size = Vector2(230,85)
    act.add_theme_font_size_override("font_size",21)
    act.pressed.connect(func(): action_pressed.emit())
    root.add_child(act)
    intro_panel = _center_panel(root,"ПОДРАБОТКА НА НОЧЬ","Хозяева уехали. Осмотри квартиру, найди ценные вещи, затем убери грязь. Следи за телефоном — они могут вернуться раньше!","НАЧАТЬ СМЕНУ",func(): action_pressed.emit())
    call_panel = _center_panel(root,"ВХОДЯЩИЙ ЗВОНОК","Хозяева звонят…","ОТВЕТИТЬ",func(): call_answered.emit(); call_panel.hide())
    ending_panel = _center_panel(root,"СМЕНА ЗАВЕРШЕНА","Результат смены","ЕЩЁ РАЗ",func(): get_tree().reload_current_scene())
    call_panel.hide()
    ending_panel.hide()

func _style(p: PanelContainer,c: Color):
    var s = StyleBoxFlat.new()
    s.bg_color = c
    s.corner_radius_top_left = 16
    s.corner_radius_top_right = 16
    s.corner_radius_bottom_left = 16
    s.corner_radius_bottom_right = 16
    s.content_margin_left = 18
    s.content_margin_right = 18
    s.content_margin_top = 12
    s.content_margin_bottom = 12
    p.add_theme_stylebox_override("panel",s)

func _center_panel(root: Control,heading: String,body: String,button_text: String,callback: Callable) -> PanelContainer:
    var p = PanelContainer.new()
    p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    p.position = Vector2(-260,-150)
    p.custom_minimum_size = Vector2(520,300)
    p.z_index = 10
    _style(p,Color(0.025,0.035,0.06,0.97))
    var col = VBoxContainer.new()
    col.add_theme_constant_override("separation",16)
    p.add_child(col)
    var h = Label.new()
    h.text = heading
    h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    h.add_theme_font_size_override("font_size",26)
    h.add_theme_color_override("font_color",Color(0.52,0.88,0.95))
    col.add_child(h)
    var b = Label.new()
    b.text = body
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.custom_minimum_size.y = 105
    b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    b.add_theme_font_size_override("font_size",18)
    col.add_child(b)
    var btn = Button.new()
    btn.text = button_text
    btn.custom_minimum_size.y = 55
    btn.pressed.connect(callback)
    col.add_child(btn)
    root.add_child(p)
    return p

func show_intro():
    intro_panel.show()
func hide_intro():
    intro_panel.hide()
func set_task(t: String):
    task_label.text = t
func update_status(loot: int,total: int,dirt: int,seconds: int):
    status_label.text = "Ценности: %d/%d   Пятна: %d   Время: %02d:%02d" % [loot,total,dirt,seconds/60,seconds%60]
    task_label.text = "Найди ценности" if loot < total else "Уборка: очисти все пятна"
func toast(t: String):
    toast_label.text = t
func show_call(message: String):
    var col = call_panel.get_child(0)
    col.get_child(1).text = message
    call_panel.show()
func show_ending(success: bool):
    var col = ending_panel.get_child(0)
    col.get_child(1).text = "Ты успел закончить уборку!" if success else "Время вышло. Хозяева уже дома."
    ending_panel.show()
func _joy_input(event: InputEvent,joy: Control):
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_index = event.index
            _move_joy(event.position,joy)
        elif event.index == touch_index:
            touch_index = -1
            move_vec = Vector2.ZERO
            movement_changed.emit(Vector2.ZERO)
            joy.queue_redraw()
    elif event is InputEventScreenDrag and event.index == touch_index:
        _move_joy(event.position,joy)
func _move_joy(pos: Vector2,joy: Control):
    move_vec = ((pos-Vector2(82,82))/55).limit_length(1)
    movement_changed.emit(move_vec)
    joy.queue_redraw()
