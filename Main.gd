extends Control

const BG := Color("#071018")
const PANEL := Color("#0b1b24")
const GREEN := Color("#55f29a")
const CYAN := Color("#54d8e8")
const MUTED := Color("#8aa4ad")
const RED := Color("#ff6b75")

const TUTORIAL_TOTAL := 5

var output: RichTextLabel
var command_input: LineEdit
var status_label: Label
var connected_to := ""
var mission_stage := 0
var tutorial_active := false
var tutorial_step := 0
var files := {
    "HELIO-7": {
        "readme.txt": "NODE: HELIO-7\nAKSES: TERBATAS\n\nSebuah relay yang terlupakan mulai mengirimkan paket terenkripsi. Temukan kunci relay dan pulihkan lognya.",
        "relay.log": "03:14:22 - paket keluar terdeteksi\n03:14:25 - rute dialihkan ke ORCHID-NODE\n03:14:27 - fragmen kunci disimpan di /vault/key.dat"
    },
    "ORCHID-NODE": {
        "key.dat": "(TERENKRIPSI)\n7f3a 91c2 e04b 5d18 a6c7 3b90\nIsi file tidak terbaca. Gunakan decrypt untuk membukanya.",
        "archive.idx": "INDEKS NODE: 2 entri\n- key.dat (terenkripsi)\n- archive.idx"
    },
    "ARCHIVE-09": {
        "archive.idx": "INDEKS ARSIP: arsip lama, tidak ada entri yang relevan dengan relay.",
        "backup.log": "02:00:01 - pencadangan selesai\nTidak ada aktivitas mencurigakan."
    }
}
var known_nodes := ["HELIO-7", "ORCHID-NODE", "ARCHIVE-09"]

func _ready() -> void:
    _build_ui()
    _print_line("[b][color=#55f29a]NEON TRACE // TERMINAL SELULER[/color][/b]")
    _print_line("Lingkungan jaringan simulasi. Tidak ada perangkat nyata yang diakses.")
    _print_line("Ketik [color=#54d8e8]help[/color] untuk melihat daftar perintah.")
    _print_line("Baru pertama main? Ketik [color=#54d8e8]tutorial[/color] untuk panduan langkah demi langkah.")
    _print_line("")
    _print_line("[color=#8aa4ad]MISI 01: RELAY YANG SENYAP[/color]")
    _print_line("Sebuah relay membocorkan lalu lintas terenkripsi. Temukan relay itu dan pulihkan fragmen kuncinya.")
    _print_line("")

func _build_ui() -> void:
    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 10)
    root.add_theme_stylebox_override("panel", _style(BG, 0))
    add_child(root)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    root.add_child(header)

    var title := Label.new()
    title.text = "NEON TRACE"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", GREEN)
    title.add_theme_font_size_override("font_size", 24)
    header.add_child(title)

    status_label = Label.new()
    status_label.text = "OFFLINE"
    status_label.add_theme_color_override("font_color", MUTED)
    header.add_child(status_label)

    var sub := Label.new()
    sub.text = "KONSOL LAPANGAN  /  BUILD 0.1"
    sub.add_theme_color_override("font_color", CYAN)
    sub.add_theme_font_size_override("font_size", 12)
    root.add_child(sub)

    var separator := ColorRect.new()
    separator.custom_minimum_size.y = 2
    separator.color = Color("#1c4650")
    root.add_child(separator)

    output = RichTextLabel.new()
    output.size_flags_vertical = Control.SIZE_EXPAND_FILL
    output.scroll_following = true
    output.bbcode_enabled = true
    output.selection_enabled = true
    output.add_theme_color_override("default_color", Color("#c8d8dc"))
    output.add_theme_font_size_override("normal_font_size", 16)
    output.add_theme_stylebox_override("normal", _style(PANEL, 10))
    root.add_child(output)

    var input_row := HBoxContainer.new()
    input_row.add_theme_constant_override("separation", 8)
    root.add_child(input_row)

    command_input = LineEdit.new()
    command_input.placeholder_text = "ketik perintah..."
    command_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    command_input.custom_minimum_size.y = 54
    command_input.add_theme_color_override("font_color", GREEN)
    command_input.add_theme_color_override("font_placeholder_color", MUTED)
    command_input.add_theme_stylebox_override("normal", _style(Color("#102630"), 8))
    command_input.add_theme_stylebox_override("focus", _style(Color("#143541"), 8))
    command_input.text_submitted.connect(_on_command_submitted)
    input_row.add_child(command_input)

    var send := Button.new()
    send.text = "KIRIM"
    send.custom_minimum_size = Vector2(82, 54)
    send.add_theme_color_override("font_color", BG)
    send.add_theme_color_override("font_hover_color", BG)
    send.add_theme_stylebox_override("normal", _style(GREEN, 8))
    send.pressed.connect(_submit_current)
    input_row.add_child(send)

    var footer := Label.new()
    footer.text = "HANYA SIMULASI LOKAL  •  SIAP OFFLINE"
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_color_override("font_color", MUTED)
    footer.add_theme_font_size_override("font_size", 10)
    root.add_child(footer)

func _style(color: Color, radius: int) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = color
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.content_margin_left = 12
    s.content_margin_right = 12
    s.content_margin_top = 8
    s.content_margin_bottom = 8
    return s

func _print_line(message: String) -> void:
    output.append_text(message + "\n")
    output.scroll_to_line(output.get_line_count())

func _submit_current() -> void:
    _on_command_submitted(command_input.text)

func _on_command_submitted(raw: String) -> void:
    var line := raw.strip_edges()
    if line.is_empty():
        return
    command_input.clear()
    _print_line("[color=#55f29a]operator@neontrace:~$[/color] " + line)
    var parts := line.split(" ", false)
    var cmd := parts[0].to_lower()
    var arg := ""
    if parts.size() > 1:
        arg = " ".join(parts.slice(1))
    _run_command(cmd, arg)

# ---------------------------------------------------------------
# TUTORIAL
# ---------------------------------------------------------------

func _tutorial_start() -> void:
    tutorial_active = true
    tutorial_step = 0
    _print_line("[b][color=#54d8e8]=== TUTORIAL NEON TRACE ===[/color][/b]")
    _print_line("Game ini adalah terminal simulasi. Kamu bermain dengan mengetik perintah, lalu menekan [b]KIRIM[/b] atau Enter.")
    _print_line("Ketik [color=#54d8e8]tutorial lewati[/color] kapan saja untuk berhenti.")
    _print_line("")
    _tutorial_show()

func _tutorial_show() -> void:
    var header := "[color=#54d8e8]TUTORIAL " + str(tutorial_step + 1) + "/" + str(TUTORIAL_TOTAL) + "[/color] "
    match tutorial_step:
        0:
            _print_line(header + "Semua aksi di game ini adalah perintah teks. Coba lihat daftar perintah dulu. Ketik: [color=#55f29a]help[/color]")
        1:
            _print_line(header + "Bagus! Sekarang cari tahu apa saja yang ada di jaringan. Ketik: [color=#55f29a]scan[/color]")
        2:
            _print_line(header + "Hasil scan menampilkan daftar node (komputer simulasi). Mari masuk ke salah satunya. Ketik: [color=#55f29a]connect HELIO-7[/color]")
        3:
            _print_line(header + "Kamu sudah terhubung. Lihat file apa saja yang ada di node ini. Ketik: [color=#55f29a]ls[/color]")
        4:
            _print_line(header + "Untuk membaca isi sebuah file, pakai cat diikuti nama file. Ketik: [color=#55f29a]cat readme.txt[/color]")

func _tutorial_expected() -> String:
    match tutorial_step:
        0:
            return "help"
        1:
            return "scan"
        2:
            return "connect HELIO-7"
        3:
            return "ls"
        4:
            return "cat readme.txt"
    return ""

func _tutorial_finish() -> void:
    tutorial_active = false
    _print_line("")
    _print_line("[b][color=#55f29a]TUTORIAL SELESAI![/color][/b]")
    _print_line("Kamu sudah menguasai dasarnya: [color=#54d8e8]scan[/color], [color=#54d8e8]connect[/color], [color=#54d8e8]ls[/color], dan [color=#54d8e8]cat[/color].")
    _print_line("Sisanya kamu selesaikan sendiri. Baca file lain untuk mencari petunjuk, dan ikuti ke mana jejaknya mengarah.")
    _print_line("Buntu? Ketik [color=#54d8e8]hint[/color] untuk petunjuk, atau [color=#54d8e8]mission[/color] untuk melihat tujuan.")
    _print_line("")

func _tutorial_progress(cmd: String, arg: String) -> void:
    if not tutorial_active:
        return
    var done := false
    match tutorial_step:
        0:
            done = cmd == "help" or cmd == "bantuan"
        1:
            done = cmd == "scan"
        2:
            done = cmd == "connect" and connected_to == "HELIO-7"
        3:
            done = cmd == "ls" and connected_to == "HELIO-7"
        4:
            done = cmd == "cat" and arg.to_lower() == "readme.txt" and connected_to == "HELIO-7"
    if done:
        tutorial_step += 1
        if tutorial_step >= TUTORIAL_TOTAL:
            _tutorial_finish()
        else:
            _print_line("")
            _tutorial_show()
    else:
        _print_line("[color=#8aa4ad]Tutorial: ketik [/color][color=#55f29a]" + _tutorial_expected() + "[/color][color=#8aa4ad] untuk melanjutkan.[/color]")

func _print_hint() -> void:
    if mission_stage >= 3:
        _print_line("Misi sudah selesai. Tidak ada petunjuk lagi.")
    elif mission_stage == 2:
        _print_line("[color=#54d8e8]PETUNJUK:[/color] Log menyebut rute berpindah ke node lain. Hubungkan ke ORCHID-NODE, lalu coba decrypt key.dat.")
    elif mission_stage == 1:
        _print_line("[color=#54d8e8]PETUNJUK:[/color] Kamu sudah masuk ke HELIO-7. Lihat file dengan ls, lalu baca relay.log dengan cat relay.log.")
    else:
        _print_line("[color=#54d8e8]PETUNJUK:[/color] Mulai dengan scan untuk melihat node, lalu connect HELIO-7.")

# ---------------------------------------------------------------
# PERINTAH
# ---------------------------------------------------------------

func _run_command(cmd: String, arg: String) -> void:
    if cmd == "tutorial":
        var a := arg.to_lower()
        if a == "lewati" or a == "skip" or a == "stop":
            if tutorial_active:
                tutorial_active = false
                _print_line("Tutorial dihentikan. Ketik [color=#54d8e8]tutorial[/color] untuk mengulang.")
            else:
                _print_line("Tutorial sedang tidak berjalan. Ketik [color=#54d8e8]tutorial[/color] untuk memulai.")
        else:
            _tutorial_start()
        return

    match cmd:
        "help", "bantuan":
            _print_line("[color=#54d8e8]PERINTAH[/color]")
            _print_line("help                 tampilkan daftar ini")
            _print_line("tutorial             mulai panduan bermain")
            _print_line("hint                 minta petunjuk misi")
            _print_line("status               lihat sesi saat ini")
            _print_line("scan                 temukan node simulasi")
            _print_line("connect <node>       hubungkan ke node yang ditemukan")
            _print_line("disconnect           tutup sesi saat ini")
            _print_line("ls                   daftar file di node terhubung")
            _print_line("cat <file>           baca isi file")
            _print_line("decrypt <file>       dekripsi file pelatihan")
            _print_line("mission              tampilkan tujuan saat ini")
            _print_line("clear                bersihkan terminal")
        "hint", "petunjuk":
            _print_hint()
        "status":
            _print_line("SESI: " + ("TERHUBUNG -> " + connected_to if connected_to != "" else "LOKAL"))
            _print_line("PROGRES MISI: " + str(mission_stage) + "/3")
        "scan":
            _print_line("[color=#54d8e8]MEMINDAI JARINGAN SIMULASI...[/color]")
            for node in known_nodes:
                _print_line("  [color=#55f29a]●[/color] " + node + "   // host fiktif")
            _print_line("3 node ditemukan.")
        "connect":
            var target := arg.to_upper()
            if target in known_nodes:
                connected_to = target
                status_label.text = "TERHUBUNG: " + target
                status_label.add_theme_color_override("font_color", GREEN)
                _print_line("[color=#55f29a]TAUTAN TERBENTUK:[/color] " + target)
                if target == "HELIO-7" and mission_stage < 1:
                    mission_stage = 1
                    _print_line("Petunjuk baru tersedia. Coba: ls")
            else:
                _print_line("[color=#ff6b75]GALAT:[/color] Node tidak dikenal. Jalankan scan dulu.")
        "disconnect":
            connected_to = ""
            status_label.text = "OFFLINE"
            status_label.add_theme_color_override("font_color", MUTED)
            _print_line("Sesi ditutup.")
        "ls":
            if connected_to == "":
                _print_line("Tidak ada koneksi aktif. Gunakan connect <node>.")
            else:
                _print_line("    ".join(files[connected_to].keys()))
        "cat":
            var fname := arg.to_lower()
            if connected_to == "":
                _print_line("Tidak ada koneksi aktif.")
            elif fname == "":
                _print_line("Pemakaian: cat <file>. Gunakan ls untuk melihat daftar file.")
            elif files[connected_to].has(fname):
                _print_line("[color=#54d8e8]--- " + fname + " ---[/color]")
                _print_line(files[connected_to][fname])
                if connected_to == "HELIO-7" and fname == "relay.log" and mission_stage < 2:
                    mission_stage = 2
                    _print_line("[color=#55f29a]PETUNJUK DITEMUKAN:[/color] rute mengarah ke ORCHID-NODE.")
            else:
                _print_line("File tidak ditemukan di " + connected_to + ": " + arg)
        "decrypt":
            if connected_to == "ORCHID-NODE" and arg.to_lower() == "key.dat":
                _print_line("[color=#55f29a]DEKRIPSI BERHASIL[/color]")
                _print_line("Fragmen berhasil dipulihkan: ORCHID-7391")
                _print_line("Ini adalah lingkungan pelatihan fiktif.")
                if mission_stage < 3:
                    mission_stage = 3
                    _print_line("[b][color=#55f29a]MISI SELESAI: RELAY YANG SENYAP[/color][/b]")
                    _print_line("Misi lainnya akan hadir di build berikutnya.")
            else:
                _print_line("Tidak bisa mendekripsi. Hubungkan ke ORCHID-NODE lalu gunakan decrypt key.dat.")
        "mission":
            if mission_stage >= 3:
                _print_line("MISI SELESAI: Relay yang Senyap.")
            else:
                _print_line("Tujuan: scan -> connect HELIO-7 -> baca relay.log -> connect ORCHID-NODE -> decrypt key.dat")
        "clear":
            output.clear()
        _:
            _print_line("[color=#ff6b75]Perintah tidak dikenal:[/color] " + cmd + ". Ketik help.")

    _tutorial_progress(cmd, arg)
