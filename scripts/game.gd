extends Node
## 全局游戏状态（自动加载单例 Game）

# ---------------- 常量 ----------------
const SOLDIER_NAMES := ["先锋", "盾卫", "游侠"]

const T_SWORD := "sword"
const T_AXE := "axe"
const WEAPON_TYPES := [T_SWORD, T_AXE]
const TYPE_NAME := {T_SWORD: "剑", T_AXE: "斧"}

const M_COPPER := "copper"
const M_IRON := "iron"
const M_STEEL := "steel"
const MATERIALS := [M_COPPER, M_IRON, M_STEEL]
const MATERIAL_NAME := {M_COPPER: "铜", M_IRON: "铁", M_STEEL: "钢"}
const MATERIAL_BASE_ATK := {M_COPPER: 10, M_IRON: 14, M_STEEL: 18}
const MATERIAL_COLOR := {
	M_COPPER: Color("d98a4b"),
	M_IRON: Color("9aa7b5"),
	M_STEEL: Color("5fa8c9"),
}
const MATERIAL_DARK := {
	M_COPPER: Color("a85f2c"),
	M_IRON: Color("6c7684"),
	M_STEEL: Color("3d7a96"),
}

const A_NONE := "none"
const A_ATK := "attack"
const A_DUR := "durability"
const ATTACHMENTS := [A_NONE, A_ATK, A_DUR]
const ATTACH_NAME := {A_NONE: "无附件", A_ATK: "攻击附件", A_DUR: "耐久附件"}

const DAILY_MATERIAL_STOCK := 3
const TOOL_UPGRADE_COST := 20

# ---------------- 局内状态 ----------------
var rng := RandomNumberGenerator.new()

var day := 1
var gold := 0
var materials := {}
var orders: Array = []
var weapons: Array = []
var forge_upgraded := false
var assemble_upgraded := false
var day_results: Array = []
## 刚结束的一场战斗结果（供结算页读取）
var pending_battle := {}

func _ready() -> void:
	rng.randomize()
	reset()

# 重新开始：清空订单、材料变化、升级和成绩
func reset() -> void:
	day = 1
	gold = 0
	forge_upgraded = false
	assemble_upgraded = false
	orders = []
	weapons = []
	day_results = []
	pending_battle = {}
	_refill_materials()
	_generate_orders()

func _refill_materials() -> void:
	materials = {
		M_COPPER: DAILY_MATERIAL_STOCK,
		M_IRON: DAILY_MATERIAL_STOCK,
		M_STEEL: DAILY_MATERIAL_STOCK,
	}

# 每天三名士兵各一张随机订单
func _generate_orders() -> void:
	orders.clear()
	for i in SOLDIER_NAMES.size():
		var wtype: String = WEAPON_TYPES[rng.randi_range(0, WEAPON_TYPES.size() - 1)]
		var mat: String = MATERIALS[rng.randi_range(0, MATERIALS.size() - 1)]
		var attach: String = A_ATK if rng.randi_range(0, 1) == 0 else A_DUR
		orders.append({
			"soldier_index": i,
			"soldier_name": SOLDIER_NAMES[i],
			"weapon_type": wtype,
			"material": mat,
			"attachment": attach,
			"delivered": false,
		})

func all_delivered() -> bool:
	for o in orders:
		if not o.delivered:
			return false
	return true

func consume_material(mat: String) -> bool:
	if materials.get(mat, 0) <= 0:
		return false
	materials[mat] -= 1
	return true

# 根据三道工序得分与选择，计算成品武器的全部属性
func build_weapon(order_index: int, wtype: String, mat: String, attach: String,
		cast_s: float, forge_s: float, assemble_s: float) -> Dictionary:
	var order: Dictionary = orders[order_index]
	var quality: float = round((cast_s + forge_s + assemble_s) / 3.0 * 10.0) / 10.0
	var type_ok: bool = wtype == order.weapon_type
	var mat_ok: bool = mat == order.material
	# 类别或材料不符合订单：有效质量减半（与总质量取整口径保持严格一致）
	var effective: float = quality if type_ok and mat_ok else round(quality * 0.5 * 10.0) / 10.0
	var atk: float = MATERIAL_BASE_ATK[mat] * (0.5 + effective / 100.0)
	atk = round(atk * 10.0) / 10.0
	var durability: int = int(floor(10.0 + effective / 5.0))
	var attach_ok: bool = attach == order.attachment
	# 附件符合需求才有加成
	if attach_ok:
		if attach == A_ATK:
			atk += 3.0
		elif attach == A_DUR:
			durability += 10
	return {
		"order_index": order_index,
		"weapon_type": wtype,
		"material": mat,
		"attachment": attach,
		"cast_score": cast_s,
		"forge_score": forge_s,
		"assemble_score": assemble_s,
		"quality": quality,
		"effective_quality": effective,
		"type_match": type_ok,
		"material_match": mat_ok,
		"attachment_match": attach_ok,
		"attack": atk,
		"durability": durability,
		"max_durability": durability,
	}

func deliver_weapon(weapon: Dictionary) -> void:
	var idx: int = weapon.order_index
	orders[idx].delivered = true
	weapons.append(weapon)

# 战斗结束：记录当天成绩与金币
func record_battle(victory: bool, groups_cleared: int, gold_earned: int) -> void:
	pending_battle = {
		"day": day,
		"victory": victory,
		"groups_cleared": groups_cleared,
		"gold_earned": gold_earned,
		"avg_quality": _day_avg_quality(),
	}
	day_results.append(pending_battle)
	gold += gold_earned

func begin_next_day() -> void:
	day += 1
	weapons = []
	_refill_materials()
	_generate_orders()

func _day_avg_quality() -> float:
	if weapons.is_empty():
		return 0.0
	var total := 0.0
	for w in weapons:
		total += w.quality
	return round(total / weapons.size() * 10.0) / 10.0

func total_gold_earned() -> int:
	var total := 0
	for r in day_results:
		total += r.gold_earned
	return total

func victories() -> int:
	var n := 0
	for r in day_results:
		if r.victory:
			n += 1
	return n
