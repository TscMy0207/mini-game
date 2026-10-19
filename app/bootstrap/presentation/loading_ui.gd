extends Control

signal retry_requested

const BACKGROUND := Color("#f4efe6")
const INK := Color("#28313b")
const MUTED := Color("#77808a")
const ACCENT := Color("#63b7ff")
const ERROR := Color("#c45c55")

var background: ColorRect
var panel: Panel
var title_label: Label
var stage_label: Label
var detail_label: Label
var percent_label: Label
var progress_bar: ProgressBar
var retry_button: Button
var _progress := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_progress(0.0, "正在启动", "准备游戏内容")

func set_progress(progress: float, title: String, detail: String) -> void:
	_progress = clampf(progress, 0.0, 1.0)
	stage_label.text = title
	detail_label.text = detail
	percent_label.text = "%d%%" % roundi(_progress * 100.0)
	progress_bar.value = _progress * 100.0
	retry_button.visible = false
	detail_label.add_theme_color_override("font_color", MUTED)

func show_failure(reason: String) -> void:
	stage_label.text = "暂时无法进入游戏"
	detail_label.text = reason
	detail_label.add_theme_color_override("font_color", ERROR)
	retry_button.visible = true

func _build_controls() -> void:
	background = ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	panel = Panel.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)
	title_label = _make_label("CAT CATCH", 34, INK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title_label)
	stage_label = _make_label("", 24, INK)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(stage_label)
	detail_label = _make_label("", 16, MUTED)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(detail_label)
	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.add_theme_stylebox_override("background", _bar_style(Color("#e6dfd3"), Color("#e6dfd3")))
	progress_bar.add_theme_stylebox_override("fill", _bar_style(ACCENT, ACCENT))
	panel.add_child(progress_bar)
	percent_label = _make_label("0%", 17, MUTED)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(percent_label)
	retry_button = Button.new()
	retry_button.text = "重新尝试"
	retry_button.visible = false
	retry_button.add_theme_font_size_override("font_size", 19)
	retry_button.add_theme_stylebox_override("normal", _button_style(Color("#f1f6ff"), Color("#8aadd8")))
	retry_button.add_theme_stylebox_override("hover", _button_style(Color("#dff0ff"), Color("#63b7ff")))
	retry_button.pressed.connect(func() -> void: retry_requested.emit())
	panel.add_child(retry_button)

func _layout() -> void:
	size = get_viewport_rect().size
	background.size = size
	var panel_size := Vector2(minf(840.0, size.x - 80.0), 380.0)
	panel.size = panel_size
	panel.position = (size - panel_size) * 0.5
	title_label.position = Vector2(36.0, 56.0)
	title_label.size = Vector2(panel_size.x - 72.0, 48.0)
	stage_label.position = Vector2(36.0, 140.0)
	stage_label.size = Vector2(panel_size.x - 72.0, 40.0)
	detail_label.position = Vector2(36.0, 188.0)
	detail_label.size = Vector2(panel_size.x - 72.0, 30.0)
	progress_bar.position = Vector2(56.0, 248.0)
	progress_bar.size = Vector2(panel_size.x - 112.0, 22.0)
	percent_label.position = Vector2(36.0, 282.0)
	percent_label.size = Vector2(panel_size.x - 72.0, 28.0)
	retry_button.position = Vector2((panel_size.x - 240.0) * 0.5, 322.0)
	retry_button.size = Vector2(240.0, 48.0)

func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffdf8")
	style.border_color = Color("#d3ccc0")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style

func _bar_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_corner_radius_all(10)
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	return style
