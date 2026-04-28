extends EditorScript

func _run():
    var scene = EditorInterface.get_edited_scene_root()
    var vbox = scene.get_node_or_null("UIManager/MarginContainer/VBoxContainer")
    if not vbox:
        print("VBoxContainer not found")
        return

    var settings = vbox.get_node_or_null("SettingsHBox")
    if not settings:
        print("SettingsHBox not found")
        return

    settings.set("layout_mode", 2)

    var selector = settings.get_node_or_null("DifficultySelector")
    if selector:
        selector.add_item("Easy")
        selector.add_item("Medium")
        selector.add_item("Hard")
        selector.select(1)

    var checkbox = settings.get_node_or_null("AiToggleCheckBox")
    if checkbox:
        checkbox.set("button_pressed", true)

    print("Settings configured successfully")
