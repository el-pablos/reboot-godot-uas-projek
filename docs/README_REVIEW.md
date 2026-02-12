# README Review — Catatan Audit Internal

## Tanggal: 2026-02-13

---

## 1. Struktur

| Issue | Detail |
|-------|--------|
| Section terlalu banyak | 12+ sections, beberapa bisa digabung |
| Urutan kurang natural | Physics/math muncul sebelum cara install — bikin user drop |
| Arsitektur terlalu detail | State machine diagram + enemy inheritance + BossBrain diagram — overkill buat README |
| Missing "Gameplay Preview" | TIDAK ada screenshot/GIF sama sekali |
| Missing quick links di atas | User harus scroll jauh buat download/play |

## 2. Konsistensi Angka

| Tempat | Angka | Fakta |
|--------|-------|-------|
| Badge header | 205 Tests | ❌ Inflated — aktual hanya **147** `func test_` |
| Quality Assurance section | 205/205 | ❌ Sama — angka benar = 147 |
| test_player_movement | README: 21 | Aktual: **17** |
| test_game_logic | README: 30 | Aktual: **21** |
| test_enemy_boss | README: 25 | Aktual: **19** |
| test_enemy_ai | README: 25 | Aktual: **24** |
| test_combat_system | README: 18 | Aktual: **18** ✅ |
| test_gameplay_qa | README: 69 | Aktual: **32** |
| test_boss_rework | README: 17 | Aktual: **16** |
| project.godot version | 0.1.0 | ❌ Footer README bilang "Version 1.0.0" |

**Rekomendasi:** Gunakan angka aktual 147. test_integration_level4.gd ada tapi tidak terdaftar di TestRunner.

## 3. Format & Tata Letak

- **Rumus fisika kepanjangan** — ~40 baris rumus kinematika di tengah README. User biasa tidak butuh ini.  
  → **Solusi:** Pindah ke `<details>` collapsible.
- **Tabel kontrol** — sudah pakai markdown table ✅
- **Level list** — sudah pakai markdown table ✅
- **Troubleshooting** — sudah pakai table tapi cuma 5 item, bisa ditambah

## 4. Kebacaan

- Paragraf "Tentang Game" — OK, ringkas
- Section "Fitur Utama" — terlalu lebar, campur movement + visual + combat + level  
  → Sebaiknya pisah per concern
- Section "Arsitektur" — teknis banget, bikin README jadi catatan dev, bukan produk showcase  
  → Pindah ke collapsible atau file terpisah

## 5. Quick Links

Yang harus ada di atas (hero section):
- [x] Play Online — ada tapi di bawah
- [x] Download Release — ada tapi di bawah  
- [ ] How to Run — tidak ada quick link
- [ ] How to Test — tidak ada quick link
- [ ] Changelog — tidak ada

## 6. Media

- **TIDAK ADA** screenshot sama sekali
- **TIDAK ADA** GIF gameplay  
- Ini problem terbesar — README tanpa gambar terlihat "belum jadi"

## 7. Bahasa

- Dominan Indonesia ✅
- Beberapa section campur Inggris (Troubleshooting, Credits)
- Istilah teknis (state machine, collision mask) OK dalam Inggris

## 8. Lain-lain

- Footer "Version 1.0.0" tidak match project.godot "0.1.0"
- `scenes/enemies/` disebut di tree tapi sebenarnya kosong
- Backup files (Player_backup.gd dkk) masih ada di repo

---

## Rencana Perbaikan

1. Redesign dengan layout "produk hero" — quick links, screenshot, controls ringkas
2. Pindah rumus fisika ke collapsible `<details>`
3. Pindah arsitektur teknis ke collapsible
4. Buat capture screenshot otomatis via CLI
5. Sinkronkan angka test dengan output aktual
6. Fix version mismatch
7. Tambah troubleshooting items
