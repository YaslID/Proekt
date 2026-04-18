extends PanelContainer
class_name MetaUpgrdeCard

@onready var name_label = %NameLabel
@onready var description_label = %DescriptionLabel
@onready var animation_player = $AnimationPlayer
@onready var purchase_button: Button = %PurchaseButton
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var progress_label: Label = %ProgressLabel
@onready var quantity_label: Label = %QuantityLabel


var upgrade: MetaUpgrade

func set_meta_upgrade(upgrade: MetaUpgrade): #для подхвата значений
	self.upgrade = upgrade #делаем общим для скрипта  параметр апгрейд
	name_label.text = upgrade.name
	description_label.text = upgrade.description
	update_progress() #появилась карта и инфа сразу обновилась

func update_progress(): #инфа на карте обновляться будет
	var quantity = 0
	quantity = MetaProgression.get_upgrade_quantity(upgrade.id)
	var is_maxed = quantity >= upgrade.max_quantity
	var currency = MetaProgression.save_data["meta_upgrade_currency"] #глобал сцена метапрогрес. желтую полоску будем обновлять. это кол собран бутыльков         
	var percent = currency / upgrade.cost
	percent = min(percent, 1) #ограничиваем процент
	progress_bar.value = percent
	purchase_button.disabled = percent < 1 || is_maxed
	if is_maxed:
		purchase_button.text = "Max"
	progress_label.text = str(currency) + "/" + str(upgrade.cost)
	quantity_label.text = "x" + str(quantity)
	

func _on_purchase_button_pressed():
	if upgrade == null:
		return
	await AutoSave.purchase_upgrade(upgrade.id, upgrade.cost)
	get_tree().call_group("meta_upgrade_card", "update_progress")
	animation_player.play("selected")
