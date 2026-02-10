# ===================================================
# BossConfig.gd - Resource konfigurasi per boss
# Project: REBOOT
# Author: el-pablos
# ===================================================
# Menyimpan parameter AI per boss.
# Dipakai oleh BossBrain untuk decision-making.
# ===================================================

extends Resource
class_name BossConfig

@export_group("Detection")
## Jarak deteksi player untuk mulai chase
@export var detect_range: float = 300.0
## Jarak kehilangan player
@export var lose_range: float = 500.0

@export_group("Chase")
## Kecepatan chase maksimal
@export var chase_speed: float = 120.0
## Akselerasi saat chase (px/s²)
@export var chase_acceleration: float = 300.0
## Jarak ideal dari player saat chase (biar nggak nempel)
@export var preferred_distance: float = 80.0

@export_group("Attack Ranges")
## Jarak untuk close/melee attack
@export var close_attack_range: float = 100.0
## Jarak minimum untuk ranged attack
@export var far_attack_min_range: float = 150.0
## Jarak maksimum untuk ranged attack
@export var far_attack_max_range: float = 350.0

@export_group("Cooldowns")
## Cooldown minimum antara serangan (detik)
@export var attack_cooldown_min: float = 1.5
## Cooldown maksimum antara serangan (detik)
@export var attack_cooldown_max: float = 3.0
## Durasi recovery setelah serangan berat (detik)
@export var recover_duration: float = 0.8
## Durasi telegraph sebelum serangan berat (detik)
@export var telegraph_duration: float = 0.4

@export_group("Arena Bounds")
## Center arena (relatif terhadap posisi awal boss)
@export var arena_center: Vector2 = Vector2.ZERO
## Ukuran arena (lebar x tinggi)
@export var arena_size: Vector2 = Vector2(600, 400)

@export_group("Phase Modifiers")
## Speed multiplier saat phase berubah
@export var phase_speed_multiplier: float = 1.3
## Cooldown multiplier saat phase berubah (lebih kecil = lebih cepat)
@export var phase_cooldown_multiplier: float = 0.7
## HP threshold untuk lebih agresif (0-1)
@export var aggression_hp_threshold: float = 0.7
## HP threshold untuk pattern tambahan (0-1)
@export var extra_pattern_hp_threshold: float = 0.4

@export_group("Reposition")
## Kecepatan reposition (dash/step-back)
@export var reposition_speed: float = 200.0
## Jarak reposition
@export var reposition_distance: float = 150.0

@export_group("Intelligence")
## Aktifkan LOS check (RayCast2D)
@export var use_line_of_sight: bool = true
## Aktifkan predictive aiming
@export var use_predictive_aim: bool = true
## Lead time untuk predictive aim (detik)
@export var aim_lead_time: float = 0.2


## Factory method untuk config default per boss
static func create_scrapper_config() -> BossConfig:
	var config := BossConfig.new()
	config.detect_range = 280.0
	config.lose_range = 450.0
	config.chase_speed = 100.0
	config.chase_acceleration = 250.0
	config.preferred_distance = 80.0
	config.close_attack_range = 110.0
	config.far_attack_min_range = 150.0
	config.far_attack_max_range = 300.0
	config.attack_cooldown_min = 1.5
	config.attack_cooldown_max = 3.0
	config.recover_duration = 0.8
	config.telegraph_duration = 0.5
	config.arena_size = Vector2(500, 300)
	config.reposition_speed = 180.0
	config.reposition_distance = 120.0
	config.use_line_of_sight = true
	config.use_predictive_aim = false  # melee-focused
	return config


static func create_sporebot_config() -> BossConfig:
	var config := BossConfig.new()
	config.detect_range = 300.0
	config.lose_range = 480.0
	config.chase_speed = 70.0
	config.chase_acceleration = 200.0
	config.preferred_distance = 180.0  # jaga jarak, spawn minions
	config.close_attack_range = 130.0
	config.far_attack_min_range = 120.0
	config.far_attack_max_range = 280.0
	config.attack_cooldown_min = 1.2
	config.attack_cooldown_max = 2.5
	config.recover_duration = 0.6
	config.telegraph_duration = 0.4
	config.arena_size = Vector2(500, 350)
	config.reposition_speed = 150.0
	config.reposition_distance = 130.0
	config.use_line_of_sight = true
	config.use_predictive_aim = true
	config.aim_lead_time = 0.15
	return config


static func create_tempest_config() -> BossConfig:
	var config := BossConfig.new()
	config.detect_range = 350.0
	config.lose_range = 500.0
	config.chase_speed = 140.0
	config.chase_acceleration = 350.0
	config.preferred_distance = 150.0  # terbang, jaga jarak
	config.close_attack_range = 80.0  # dive strike
	config.far_attack_min_range = 100.0
	config.far_attack_max_range = 350.0
	config.attack_cooldown_min = 1.0
	config.attack_cooldown_max = 2.0
	config.recover_duration = 0.5
	config.telegraph_duration = 0.35
	config.arena_size = Vector2(500, 400)
	config.reposition_speed = 250.0
	config.reposition_distance = 180.0
	config.use_line_of_sight = true
	config.use_predictive_aim = true
	config.aim_lead_time = 0.25
	return config


static func create_overlord_config() -> BossConfig:
	var config := BossConfig.new()
	config.detect_range = 450.0
	config.lose_range = 600.0
	config.chase_speed = 80.0
	config.chase_acceleration = 200.0
	config.preferred_distance = 100.0
	config.close_attack_range = 150.0
	config.far_attack_min_range = 120.0
	config.far_attack_max_range = 400.0
	config.attack_cooldown_min = 1.0
	config.attack_cooldown_max = 2.5
	config.recover_duration = 1.0
	config.telegraph_duration = 0.6
	config.arena_size = Vector2(640, 400)
	config.phase_speed_multiplier = 1.4
	config.phase_cooldown_multiplier = 0.6
	config.reposition_speed = 160.0
	config.reposition_distance = 200.0
	config.use_line_of_sight = true
	config.use_predictive_aim = true
	config.aim_lead_time = 0.3
	return config
