extends CanvasLayer

signal action_pressed
signal crouch_pressed
signal location_selected(location_id: String)
signal movement_changed(direction: Vector2)
signal call_answered
signal call_declined
signal pause_pressed
signal resume_pressed
signal restart_pressed
signal cutscene_skipped

var _root: Control
var _status_label: Label
var _task_label: Label
var _toast_label: Label
var _action_button: Button
var _alert_bar: ProgressBar
var _alert_fill: StyleBoxFlat
var _joy: Control
var _move_vec := Vector2.ZERO
var _touch_index: int = -1
var _toast_time: float = 0.0
var _intro_panel: PanelContainer
var _intro_body: Label
var _apartment_button: Button
var _store_button: Button
var _selected_location: String = "apartment"
var _call_panel: PanelContainer
var _call_label: Label
var _pause_panel: PanelContainer
var _ending_panel: PanelContainer
var _intro_overlay: ColorRect
var _call_overlay: ColorRect
var _pause_overlay: ColorRect
var _ending_overlay: ColorRect
var _cutscene_overlay: ColorRect
var _cutscene_panel: PanelContainer
var _cutscene_label: Label
var _ending_heading: Label
var _ending_body: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _root = Control.new()
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_root)
    _build_hud()
    _intro_overlay = _make_overlay("IntroOverlay")
    _intro_panel = _center_panel("НАЧАЛО СМЕНЫ", "Выбери объект, где пройдёт ночная смена. Собери ценности, убери все пятна и выйди до возвращения хозяев. Не задерживайся в поле зрения камер: присядь, чтобы снизить риск обнаружения.", "НАЧАТЬ СМЕНУ", func(): action_pressed.emit(), true)
    _call_overlay = _make_overlay("CallOverlay")
    _call_panel = _build_call_panel()
    _pause_overlay = _make_overlay("PauseOverlay")
    _pause_panel = _build_pause_panel()
    _ending_overlay = _make_overlay("EndingOverlay")
    _ending_panel = _build_ending_panel()
    _cutscene_overlay = _make_overlay("CutsceneOverlay")
    _cutscene_overlay.color = Color(0.005, 0.012, 0.025, 0.25)
    _cutscene_panel = _build_cutscene_panel()
    _hide_all_overlays()
    _intro_panel.show()
    _intro_overlay.show()

func _process(delta: float) -> void:
    if _toast_time > 0.0:
        _toast_time -= delta
        if _toast_time <= 0.0 and is_instance_valid(_toast_label):
            _toast_label.hide()

func _build_hud() -> void:
    var top_panel := PanelContainer.new()
    top_panel.name = "MissionHUD"
    top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    top_panel.offset_left = 18.0
    top_panel.offset_top = 18.0
    top_panel.offset_right = 478.0
    top_panel.offset_bottom = 166.0
    _style_panel(top_panel, Color(0.018, 0.035, 0.055, 0.91), Color(0.16, 0.45, 0.55))
    _root.add_child(top_panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 4)
    top_panel.add_child(column)
    var title := Label.new()
    title.text = "HOW TO SUCK   /   NIGHT SHIFT"
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color(0.48, 0.87, 0.94))
    column.add_child(title)
    _status_label = Label.new()
    _status_label.text = "Ценности: 0/5    Пятна: 7    04:00"
    _status_label.add_theme_font_size_override("font_size", 17)
    _status_label.add_theme_color_override("font_color", Color(0.91, 0.93, 0.94))
    column.add_child(_status_label)
    _task_label = Label.new()
    _task_label.text = "Найди 5 ценностей"
    _task_label.add_theme_font_size_override("font_size", 16)
    _task_label.add_theme_color_override("font_color", Color(0.98, 0.74, 0.36))
    _task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(_task_label)
    var alert_caption := Label.new()
    alert_caption.text = "ТРЕВОГА КАМЕР"
    alert_caption.add_theme_font_size_override("font_size", 11)
    alert_caption.add_theme_color_override("font_color", Color(0.72, 0.77, 0.83))
    column.add_child(alert_caption)
    _alert_bar = ProgressBar.new()
    _alert_bar.custom_minimum_size = Vector2(0.0, 12.0)
    _alert_bar.min_value = 0.0
    _alert_bar.max_value = 100.0
    _alert_bar.value = 0.0
    _alert_bar.show_percentage = false
    var track := StyleBoxFlat.new()
    track.bg_color = Color(0.07, 0.1, 0.13)
    track.corner_radius_top_left = 5
    track.corner_radius_top_right = 5
    track.corner_radius_bottom_left = 5
    track.corner_radius_bottom_right = 5
    _alert_fill = StyleBoxFlat.new()
    _alert_fill.bg_color = Color(0.18, 0.72, 0.54)
    _alert_fill.corner_radius_top_left = 5
    _alert_fill.corner_radius_top_right = 5
    _alert_fill.corner_radius_bottom_left = 5
    _alert_fill.corner_radius_bottom_right = 5
    _alert_bar.add_theme_stylebox_override("background", track)
    _alert_bar.add_theme_stylebox_override("fill", _alert_fill)
    column.add_child(_alert_bar)
    var toast := Label.new()
    toast.name = "Toast"
    toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    toast.offset_left = -300.0
    toast.offset_top = 22.0
    toast.offset_right = 300.0
    toast.offset_bottom = 65.0
    toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast.add_theme_font_size_override("font_size", 20)
    toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.59))
    toast.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
    toast.add_theme_constant_override("shadow_offset_x", 1)
    toast.add_theme_constant_override("shadow_offset_y", 2)
    _root.add_child(toast)
    _toast_label = toast
    _toast_label.hide()
    _joy = Control.new()
    _joy.name = "TouchJoystick"
    _joy.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    _joy.offset_left = 28.0
    _joy.offset_top = -206.0
    _joy.offset_right = 204.0
    _joy.offset_bottom = -30.0
    _joy.mouse_filter = Control.MOUSE_FILTER_STOP
    _joy.draw.connect(_draw_joystick)
    _joy.gui_input.connect(_joy_input)
    _root.add_child(_joy)
    var move_hint := Label.new()
    move_hint.text = "ДВИЖЕНИЕ"
    move_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    move_hint.offset_left = 62.0
    move_hint.offset_top = -31.0
    move_hint.offset_right = 180.0
    move_hint.offset_bottom = -8.0
    move_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    move_hint.add_theme_font_size_override("font_size", 12)
    move_hint.add_theme_color_override("font_color", Color(0.78, 0.86, 0.91))
    _root.add_child(move_hint)
    _action_button = Button.new()
    _action_button.name = "ActionButton"
    _action_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    _action_button.offset_left = -286.0
    _action_button.offset_top = -114.0
    _action_button.offset_right = -22.0
    _action_button.offset_bottom = -25.0
    _action_button.text = "ВЗЯТЬ / МЫТЬ"
    _action_button.add_theme_font_size_override("font_size", 19)
    _style_button(_action_button, Color(0.09, 0.39, 0.48), Color(0.13, 0.54, 0.61))
    _action_button.pressed.connect(func(): action_pressed.emit())
    _root.add_child(_action_button)
    var crouch_button := Button.new()
    crouch_button.name = "CrouchButton"
    crouch_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    crouch_button.offset_left = -216.0
    crouch_button.offset_top = -174.0
    crouch_button.offset_right = -22.0
    crouch_button.offset_bottom = -124.0
    crouch_button.text = "ПРИСЕСТЬ"
    crouch_button.add_theme_font_size_override("font_size", 16)
    _style_button(crouch_button, Color(0.17, 0.27, 0.34), Color(0.24, 0.39, 0.46))
    crouch_button.pressed.connect(func(): crouch_pressed.emit())
    _root.add_child(crouch_button)
    var pause_button := Button.new()
    pause_button.name = "PauseButton"
    pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    pause_button.offset_left = -126.0
    pause_button.offset_top = 18.0
    pause_button.offset_right = -18.0
    pause_button.offset_bottom = 70.0
    pause_button.text = "Ⅱ  ПАУЗА"
    pause_button.add_theme_font_size_override("font_size", 15)
    _style_button(pause_button, Color(0.08, 0.13, 0.18, 0.95), Color(0.15, 0.25, 0.31, 0.98))
    pause_button.pressed.connect(func(): pause_pressed.emit())
    _root.add_child(pause_button)

func _draw_joystick() -> void:
    if not is_instance_valid(_joy):
        return
    _joy.draw_circle(Vector2(88.0, 88.0), 78.0, Color(0.035, 0.075, 0.105, 0.74))
    _joy.draw_arc(Vector2(88.0, 88.0), 78.0, 0.0, TAU, 56, Color(0.34, 0.69, 0.77, 0.85), 3.0)
    _joy.draw_circle(Vector2(88.0 + _move_vec.x * 43.0, 88.0 + _move_vec.y * 43.0), 28.0, Color(0.25, 0.58, 0.67, 0.96))
    _joy.draw_arc(Vector2(88.0 + _move_vec.x * 43.0, 88.0 + _move_vec.y * 43.0), 28.0, 0.0, TAU, 36, Color(0.63, 0.89, 0.94, 0.9), 2.0)

func _joy_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_index = event.index
            _move_joystick(event.position)
        elif event.index == _touch_index:
            _touch_index = -1
            _move_vec = Vector2.ZERO
            movement_changed.emit(Vector2.ZERO)
            _joy.queue_redraw()
    elif event is InputEventScreenDrag and event.index == _touch_index:
        _move_joystick(event.position)

func _move_joystick(position_value: Vector2) -> void:
    _move_vec = ((position_value - Vector2(88.0, 88.0)) / 53.0).limit_length(1.0)
    movement_changed.emit(_move_vec)
    _joy.queue_redraw()

func _style_panel(panel: PanelContainer, color: Color, border: Color = Color(0.12, 0.26, 0.32)) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(1)
    style.corner_radius_top_left = 16
    style.corner_radius_top_right = 16
    style.corner_radius_bottom_left = 16
    style.corner_radius_bottom_right = 16
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", style)

func _style_button(button: Button, base_color: Color, hover_color: Color) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = base_color
    normal.corner_radius_top_left = 12
    normal.corner_radius_top_right = 12
    normal.corner_radius_bottom_left = 12
    normal.corner_radius_bottom_right = 12
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = hover_color
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(hover_color.r * 0.85, hover_color.g * 0.85, hover_color.b * 0.85)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
    button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

func _make_overlay(node_name: String) -> ColorRect:
    var overlay := ColorRect.new()
    overlay.name = node_name
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.color = Color(0.005, 0.012, 0.025, 0.78)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.z_index = 5
    _root.add_child(overlay)
    overlay.hide()
    return overlay

func _center_panel(heading: String, body_text: String, button_text: String, callback: Callable, show_art: bool = false) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.offset_left = -280.0
    panel.offset_top = -244.0 if show_art else -158.0
    panel.offset_right = 280.0
    panel.offset_bottom = 244.0 if show_art else 158.0
    panel.z_index = 10
    _style_panel(panel, Color(0.018, 0.032, 0.052, 0.98), Color(0.17, 0.49, 0.57))
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    panel.add_child(column)
    if show_art:
        var artwork := TextureRect.new()
        artwork.texture = load("res://assets/title_art.svg")
        artwork.custom_minimum_size = Vector2(480.0, 105.0)
        artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        column.add_child(artwork)
    var title := Label.new()
    title.text = heading
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Color(0.53, 0.89, 0.95))
    column.add_child(title)
    var body := Label.new()
    body.text = body_text
    body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.custom_minimum_size = Vector2(490.0, 95.0)
    body.add_theme_font_size_override("font_size", 17)
    body.add_theme_color_override("font_color", Color(0.85, 0.89, 0.92))
    column.add_child(body)
    if show_art:
        _intro_body = body
        var location_header := Label.new()
        location_header.text = "ВЫБЕРИ ОБЪЕКТ"
        location_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        location_header.add_theme_font_size_override("font_size", 13)
        location_header.add_theme_color_override("font_color", Color(0.55, 0.72, 0.77))
        column.add_child(location_header)
        var location_row := HBoxContainer.new()
        location_row.add_theme_constant_override("separation", 12)
        column.add_child(location_row)
        _apartment_button = Button.new()
        _apartment_button.text = "КВАРТИРА"
        _apartment_button.custom_minimum_size.y = 48.0
        _apartment_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _style_button(_apartment_button, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
        _apartment_button.pressed.connect(func(): _choose_location("apartment"))
        location_row.add_child(_apartment_button)
        _store_button = Button.new()
        _store_button.text = "МАГАЗИН"
        _store_button.custom_minimum_size.y = 48.0
        _store_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _style_button(_store_button, Color(0.08, 0.13, 0.18), Color(0.15, 0.25, 0.31))
        _store_button.pressed.connect(func(): _choose_location("store"))
        location_row.add_child(_store_button)
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size.y = 52.0
    button.add_theme_font_size_override("font_size", 18)
    _style_button(button, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
    button.pressed.connect(callback)
    column.add_child(button)
    _root.add_child(panel)
    if show_art:
        _choose_location(_selected_location)
    return panel

func _choose_location(location_id: String) -> void:
    if location_id != "apartment" and location_id != "store":
        return
    _selected_location = location_id
    if is_instance_valid(_intro_body):
        if location_id == "apartment":
            _intro_body.text = "КВАРТИРА • Осмотри кухню, гостиную, спальню и ванную. Пять ценностей, семь пятен и один выход. Присядь, чтобы камеры замечали тебя хуже."
        else:
            _intro_body.text = "МАГАЗИН • Исследуй торговые ряды и кассу. Пять ценностей, семь разливов и камеры под потолком. Присядь, чтобы снизить риск обнаружения."
    _refresh_location_buttons()
    location_selected.emit(location_id)

func _refresh_location_buttons() -> void:
    if is_instance_valid(_apartment_button):
        if _selected_location == "apartment":
            _style_button(_apartment_button, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
        else:
            _style_button(_apartment_button, Color(0.055, 0.09, 0.12), Color(0.13, 0.21, 0.25))
    if is_instance_valid(_store_button):
        if _selected_location == "store":
            _style_button(_store_button, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
        else:
            _style_button(_store_button, Color(0.055, 0.09, 0.12), Color(0.13, 0.21, 0.25))

func _build_call_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.offset_left = -270.0
    panel.offset_top = -150.0
    panel.offset_right = 270.0
    panel.offset_bottom = 150.0
    panel.z_index = 10
    _style_panel(panel, Color(0.023, 0.031, 0.05, 0.99), Color(0.64, 0.39, 0.18))
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 16)
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "ВХОДЯЩИЙ ЗВОНОК"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 25)
    heading.add_theme_color_override("font_color", Color(0.98, 0.72, 0.35))
    column.add_child(heading)
    _call_label = Label.new()
    _call_label.text = "Хозяева звонят…"
    _call_label.custom_minimum_size.y = 92.0
    _call_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _call_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _call_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _call_label.add_theme_font_size_override("font_size", 18)
    column.add_child(_call_label)
    var buttons := HBoxContainer.new()
    buttons.add_theme_constant_override("separation", 12)
    column.add_child(buttons)
    var answer := Button.new()
    answer.text = "ОТВЕТИТЬ"
    answer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    answer.custom_minimum_size.y = 50.0
    _style_button(answer, Color(0.12, 0.45, 0.38), Color(0.16, 0.6, 0.47))
    answer.pressed.connect(func(): call_answered.emit())
    buttons.add_child(answer)
    var decline := Button.new()
    decline.text = "СБРОСИТЬ"
    decline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    decline.custom_minimum_size.y = 50.0
    _style_button(decline, Color(0.38, 0.15, 0.14), Color(0.58, 0.2, 0.17))
    decline.pressed.connect(func(): call_declined.emit())
    buttons.add_child(decline)
    _root.add_child(panel)
    panel.hide()
    return panel

func _build_pause_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.offset_left = -230.0
    panel.offset_top = -145.0
    panel.offset_right = 230.0
    panel.offset_bottom = 145.0
    panel.z_index = 10
    _style_panel(panel, Color(0.018, 0.032, 0.052, 0.98))
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 16)
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "ПАУЗА"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 27)
    heading.add_theme_color_override("font_color", Color(0.53, 0.89, 0.95))
    column.add_child(heading)
    var resume := Button.new()
    resume.text = "ПРОДОЛЖИТЬ"
    resume.custom_minimum_size.y = 50.0
    _style_button(resume, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
    resume.pressed.connect(func(): resume_pressed.emit())
    column.add_child(resume)
    var restart := Button.new()
    restart.text = "НАЧАТЬ ЗАНОВО"
    restart.custom_minimum_size.y = 50.0
    _style_button(restart, Color(0.15, 0.2, 0.25), Color(0.22, 0.3, 0.36))
    restart.pressed.connect(func(): restart_pressed.emit())
    column.add_child(restart)
    _root.add_child(panel)
    panel.hide()
    return panel

func _build_cutscene_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_left = 210.0
    panel.offset_top = -150.0
    panel.offset_right = -210.0
    panel.offset_bottom = -18.0
    panel.z_index = 12
    _style_panel(panel, Color(0.018, 0.032, 0.052, 0.96), Color(0.17, 0.49, 0.57))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    panel.add_child(row)
    _cutscene_label = Label.new()
    _cutscene_label.text = ""
    _cutscene_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _cutscene_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _cutscene_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _cutscene_label.add_theme_font_size_override("font_size", 18)
    _cutscene_label.add_theme_color_override("font_color", Color(0.9, 0.93, 0.95))
    row.add_child(_cutscene_label)
    var skip := Button.new()
    skip.text = "ПРОПУСТИТЬ"
    skip.custom_minimum_size = Vector2(138.0, 48.0)
    _style_button(skip, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
    skip.pressed.connect(func(): cutscene_skipped.emit())
    row.add_child(skip)
    _root.add_child(panel)
    panel.hide()
    return panel

func _build_ending_panel() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    panel.offset_left = -275.0
    panel.offset_top = -180.0
    panel.offset_right = 275.0
    panel.offset_bottom = 180.0
    panel.z_index = 10
    _style_panel(panel, Color(0.018, 0.032, 0.052, 0.99), Color(0.19, 0.57, 0.51))
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    panel.add_child(column)
    _ending_heading = Label.new()
    _ending_heading.text = "СМЕНА ЗАВЕРШЕНА"
    _ending_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _ending_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _ending_heading.add_theme_font_size_override("font_size", 25)
    _ending_heading.add_theme_color_override("font_color", Color(0.53, 0.89, 0.95))
    column.add_child(_ending_heading)
    _ending_body = Label.new()
    _ending_body.text = ""
    _ending_body.custom_minimum_size.y = 105.0
    _ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _ending_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _ending_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _ending_body.add_theme_font_size_override("font_size", 18)
    column.add_child(_ending_body)
    var restart := Button.new()
    restart.text = "ЕЩЁ РАЗ"
    restart.custom_minimum_size.y = 54.0
    _style_button(restart, Color(0.1, 0.4, 0.48), Color(0.14, 0.54, 0.61))
    restart.pressed.connect(func(): restart_pressed.emit())
    column.add_child(restart)
    _root.add_child(panel)
    panel.hide()
    return panel

func show_intro() -> void:
    _intro_overlay.show()
    _intro_panel.show()

func hide_intro() -> void:
    _intro_overlay.hide()
    _intro_panel.hide()

func set_task(message: String) -> void:
    _task_label.text = message

func update_status(loot: int, total: int, dirt: int, seconds: int, alert: float, started: bool) -> void:
    _status_label.text = "ЦЕННОСТИ %d/%d    ПЯТНА %d    %02d:%02d" % [loot, total, dirt, seconds / 60, seconds % 60]
    _alert_bar.value = alert
    if alert >= 65.0:
        _alert_fill.bg_color = Color(0.88, 0.18, 0.15)
    elif alert >= 32.0:
        _alert_fill.bg_color = Color(0.95, 0.57, 0.17)
    else:
        _alert_fill.bg_color = Color(0.18, 0.72, 0.54)
    if started:
        if loot < total:
            _task_label.text = "ЦЕЛЬ: найди все ценности"
        elif dirt > 0:
            _task_label.text = "ЦЕЛЬ: убери оставшиеся пятна"
        else:
            _task_label.text = "ЦЕЛЬ: найди выход"
    _alert_bar.queue_redraw()

func set_action_hint(message: String) -> void:
    _action_button.text = message

func set_crouch_state(enabled: bool) -> void:
    var button := _root.get_node_or_null("CrouchButton") as Button
    if not is_instance_valid(button):
        return
    button.text = "ВСТАТЬ" if enabled else "ПРИСЕСТЬ"
    if enabled:
        _style_button(button, Color(0.48, 0.29, 0.12), Color(0.62, 0.38, 0.15))
    else:
        _style_button(button, Color(0.17, 0.27, 0.34), Color(0.24, 0.39, 0.46))

func toast(message: String) -> void:
    _toast_label.text = message
    _toast_label.show()
    _toast_time = 3.2

func show_cutscene(message: String) -> void:
    _cutscene_label.text = message
    _cutscene_overlay.show()
    _cutscene_panel.show()

func hide_cutscene() -> void:
    _cutscene_overlay.hide()
    _cutscene_panel.hide()

func show_call(message: String) -> void:
    _call_label.text = message
    _call_overlay.show()
    _call_panel.show()

func hide_call() -> void:
    _call_overlay.hide()
    _call_panel.hide()

func show_pause(visible: bool) -> void:
    if visible:
        _pause_overlay.show()
        _pause_panel.show()
    else:
        _pause_overlay.hide()
        _pause_panel.hide()

func show_ending(success: bool, heading: String, message: String, seconds_left: int, alert: float = 0.0) -> void:
    _ending_heading.text = heading
    _ending_heading.add_theme_color_override("font_color", Color(0.35, 0.88, 0.62) if success else Color(1.0, 0.38, 0.28))
    var details := message
    if success:
        var rank := "C"
        if seconds_left >= 135 and alert <= 20.0:
            rank = "S"
        elif seconds_left >= 95 and alert <= 45.0:
            rank = "A"
        elif seconds_left >= 55:
            rank = "B"
        details += "\nОсталось времени: %d:%02d." % [seconds_left / 60, seconds_left % 60]
        details += "\nРанг смены: %s  •  Подозрение: %d%%" % [rank, int(alert)]
    _ending_body.text = details
    _ending_overlay.show()
    _ending_panel.show()

func _hide_all_overlays() -> void:
    _intro_overlay.hide()
    _intro_panel.hide()
    _call_overlay.hide()
    _call_panel.hide()
    _pause_overlay.hide()
    _pause_panel.hide()
    _ending_overlay.hide()
    _ending_panel.hide()
    _cutscene_overlay.hide()
    _cutscene_panel.hide()
