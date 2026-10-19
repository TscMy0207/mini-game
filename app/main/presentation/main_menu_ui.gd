extends Control

signal start_requested

const INK := Color("#28313b")
const MUTED := Color("#77808a")
const BG := Color("#f4efe6")
const CARD := Color("#fffdf8")
const ACCENT := Color("#6bd990")
const ACCENT_BORDER := Color("#83c99e")

var background: ColorRect
var card: Panel
var start_button: Button
var status_label: Label

# 主界面是独立 UI 资源，由 UIService 动态加载；这里只负责展示和发送用户意图。
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_controls()
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

func _build_controls() -> void:
	background = ColorRect.new()
	background.name = "Background"
	background.color = BG
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var brand := _label("CAT CATCH", 30, INK)
	brand.name = "BrandLabel"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(brand)

	var subtitle := _label("猫咪收集挑战", 18, MUTED)
	subtitle.name = "SubtitleLabel"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

	card = Panel.new()
	card.name = "MainMenuCard"
	card.add_theme_stylebox_override("panel", _panel_style(CARD, Color("#d3ccc0"), 24))
	add_child(card)

	var title := _label("准备好接住猫咪了吗？", 26, INK)
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)

	var description := _label("拖动同色盒子，吸收棋盘上的猫咪", 17, MUTED)
	description.name = "DescriptionLabel"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(description)

	start_button = Button.new()
	start_button.name = "StartGameButton"
	start_button.text = "开始游戏"
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.add_theme_color_override("font_color", INK)
	start_button.add_theme_stylebox_override("normal", _panel_style(ACCENT, ACCENT_BORDER, 14))
	start_button.add_theme_stylebox_override("hover", _panel_style(Color("#7be3a0"), Color("#5caf7b"), 14))
	start_button.add_theme_stylebox_override("pressed", _panel_style(Color("#55c87d"), Color("#4a9f68"), 14))
	start_button.pressed.connect(_on_start_pressed)
	card.add_child(start_button)

	status_label = _label("单机游戏 · 无需联网", 14, MUTED)
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

func _on_start_pressed() -> void:
	start_button.disabled = true
	status_label.text = "正在进入游戏…"
	start_requested.emit()

func show_framework_ready() -> void:
	status_label.text = "框架已就绪 · 等待业务模块接入"
	start_button.text = "框架运行正常"

func _on_viewport_resized() -> void:
	size = get_viewport_rect().size
	if background != null:
		background.size = size
	if card == null:
		return
	var card_size := Vector2(minf(620.0, size.x - 80.0), 360.0)
	card.size = card_size
	card.position = Vector2((size.x - card_size.x) * 0.5, size.y * 0.42 - card_size.y * 0.5)
	var card_width := card_size.x
	var title := card.get_node("TitleLabel") as Label
	title.position = Vector2(28, 42)
	title.size = Vector2(card_width - 56, 42)
	var description := card.get_node("DescriptionLabel") as Label
	description.position = Vector2(28, 104)
	description.size = Vector2(card_width - 56, 32)
	start_button.position = Vector2(48, 190)
	start_button.size = Vector2(card_width - 96, 72)
	var brand := get_node("BrandLabel") as Label
	brand.position = Vector2(40, size.y * 0.16)
	brand.size = Vector2(size.x - 80, 44)
	var subtitle := get_node("SubtitleLabel") as Label
	subtitle.position = Vector2(40, size.y * 0.16 + 50)
	subtitle.size = Vector2(size.x - 80, 32)
	status_label.position = Vector2(40, size.y - 84)
	status_label.size = Vector2(size.x - 80, 28)

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel_style(fill: Color, border: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(radius))
	return style
