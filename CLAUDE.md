# Godot UI Snippets - Usage Notes

このリポジトリは Godot 4.6 向けの UI スニペット集（`addons/ui_snippets/` 配下）と、デモ用プロジェクト本体（`demos/` 配下）から成る。新しい UI を組むときは以下のスニペットを優先的に再利用する。

## アーキテクチャ要点

- **アニメーション背景・枠は `UISnipAnimatedPanel`**: 内部は `NinePatchRect` 二層 + 自前フレームスケジューラ。`SpriteFrames` を入力とし、フレーム数 1（静止画）でも N（アニメ）でも同一 API で動作。`AnimatedSprite2D` は Control 階層と相性が悪いので使わない。
- **状態遷移アニメは Tween**: `UISnipAnimator`（static helpers）が `fade / slide / pop / shake / typewriter` を提供。Tween は `node.create_tween()` で生成し、ノード破棄で自動停止される。
- **ダイアログ開閉は AnimationPlayer + Tween フォールバック**: `base_dialog.tscn` の `Root/AnimationPlayer` に `open` / `close` を入れれば優先される。空なら `UISnipAnimator.pop_in/pop_out`。
- **シーン遷移は autoload `UISnipSceneTransition`**: `project.godot` で登録済み（`/root/UISnipSceneTransition`）。

## 主要 API（呼び出し例）

### AnimatedPanel
```gdscript
@export var background_frames: SpriteFrames  # 1 枚でも複数枚でも可
panel.background_frames = sprite_frames
panel.bg_patch_margin = 16  # 9-slice
panel.paused = true / false
panel.set_frame(2)
```

### Tween ヘルパ（UISnipAnimator）
```gdscript
UISnipAnimator.fade_in(node, 0.2)
UISnipAnimator.pop_in(control, 1.1, 0.25)
UISnipAnimator.typewriter(label, "text", 40.0)
await UISnipAnimator.slide_out(node, Vector2.LEFT, 32.0, 0.25).finished
```

### ボタン
```gdscript
# UISnipAnimatedButton（addons/ui_snippets/buttons/animated_button.tscn）を instance
# インスペクタで frames_idle / frames_hover / frames_press / frames_focus / frames_disabled を差し替え

# 派生:
# - UISnipIconButton: icon_texture / icon_size を export
# - UISnipToggleButton: frames_off / frames_on
# - UISnipMenuButton: labels (PackedStringArray) を渡すとカーソル付き縦メニューに
```

### ダイアログ（すべて `await` で結果取得可能）
```gdscript
await UISnipMessageDialog.popup(self, "本文")           # → null
var ok: bool = await UISnipConfirmDialog.popup(self, "削除しますか？")
var idx: int = await UISnipChoiceDialog.popup(self, "難易度:",
    PackedStringArray(["Easy", "Hard"]))
var name = await UISnipInputDialog.popup(self, "お名前:", "Player")  # Variant: String or null

var dlg := UISnipProgressDialog.popup(self, "Loading...", true)  # 戻り値はインスタンス
dlg.set_progress(0.5)
dlg.cancelled.connect(...)

UISnipToast.show_toast(self, "Saved!", 1.5,
    UISnipToast.ToastPosition.BOTTOM_CENTER)
```

`base_dialog` の挙動: `is_modal`, `close_on_backdrop`, `close_on_esc`, `signal closed(result: Variant)`。

### シーン遷移
```gdscript
# 別シーンへ
await UISnipSceneTransition.change_scene_to_file("res://next.tscn",
    UISnipSceneTransition.Type.FADE, 0.4)

# in-place 入れ替え
await UISnipSceneTransition.swap_subscene(host,
    func(): return packed.instantiate(),
    UISnipSceneTransition.Type.IRIS, 0.5)

# 個別フェーズ
await UISnipSceneTransition.transition_out(t, 0.4)
do_work()
await UISnipSceneTransition.transition_in(t, 0.4)
```

種類: `FADE`, `SLIDE_LEFT/RIGHT/UP/DOWN`, `IRIS`, `FRAMES`。`FRAMES` は autoload インスタンスの `frames` プロパティ（`SpriteFrames`）でテーマ画像差し替え可。

### サムネイル付きページネーションリスト（リスト選択）
```gdscript
var list := preload("res://addons/ui_snippets/lists/thumbnail_list.tscn").instantiate()
list.per_page = 3                  # 1 ページに表示する件数
list.items = [...]                  # Array[UISnipThumbnailItem]
add_child(list)
list.selection_changed.connect(func(idx, item): print(item.label))
list.item_activated.connect(func(idx, item): print("activated", idx))
list.page_changed.connect(func(p, total): pass)

# Item Resource:
var it := UISnipThumbnailItem.new()
it.label = "..."
it.thumbnail = some_texture
it.data = anything   # 任意メタデータ

# プログラム制御
list.next_page() / list.prev_page() / list.go_to_page(2, true)
list.focus_index(5)
list.get_focused()  # → UISnipThumbnailItem or null
```

入力: マウスホイール / Prev・Next ボタン / `ui_page_up` / `ui_page_down` でページ送り。矢印キー・Tab で同ページ内のスロット間フォーカス移動。Enter / クリックで `item_activated`。

カーソル: `cursor_frames: SpriteFrames` を指定すると `UISnipAnimatedPanel` 駆動のアニメーションカーソル、未指定なら `cursor_text`（既定 `▶`）の Label にフォールバック。`cursor_offset` でフォーカススロットからの相対位置を調整。

## ファイル配置ルール

- 新規スニペット（再利用部品）は `addons/ui_snippets/{core,buttons,dialogs,transitions}/` に配置。
- スクリプトはすべて `class_name UISnip*` プレフィックスで衝突回避。
- エディタプレビューが欲しいスニペットは `@tool` を付け、重い処理は `if not Engine.is_editor_hint():` でガード。
- 入力 I/F に `SpriteFrames` を受けるなら、内部では `UISnipFrameAnimator.extract_from_sprite_frames(sf, anim)` で `Array[Texture2D]` に展開して `NinePatchRect` 等に流す。
- デモは `demos/` 配下に `.tscn` + `.gd` ペアで作成し、`demos/main.tscn` のトップバーに切替ボタンを追加（`main.gd` の `_swap` を呼ぶ）。

## アセット差し替え

- プレースホルダ画像は `assets/ui/placeholder/{backgrounds,borders,buttons}/` に SVG + 対応する `SpriteFrames` (.tres) で配置。
- ユーザーが差し替えるときはインスペクタで `SpriteFrames` 系プロパティをドラッグ&ドロップ。フレーム数 1 / N どちらでも OK。
- 9-slice 用に `bg_patch_margin` / `border_patch_margin` を調整。

## Godot バージョン互換

- `project.godot` は `config/features=PackedStringArray("4.6", "GL Compatibility")`。
- 4.6 のシグナル変更（`AnimationPlayer.animation_finished` の StringName 化）には対応済み。`grab_focus` / `has_focus` の追加オプション引数は使っていない（後方互換）。
- `.uid` ファイルはコミット対象（`.gitignore` に含めない）。

## やってはいけない / 注意点

- `Theme` の StyleBox は使わず、見た目は `AnimatedPanel` のオーバーレイに任せる（ボタンは `flat = true` でエンジン描画を消す）。
- ダイアログを `Node` ルートにせず `CanvasLayer` ルートのまま。`process_mode = PROCESS_MODE_ALWAYS` を維持。
- `play("open")` 中の二重起動は `is_playing()` チェックでガード（既に対応済み）。
- 入力ブロックは `mouse_filter = MOUSE_FILTER_STOP` のフルレクト Backdrop で行う。
- フォントが豆腐になる場合は `assets/ui/fonts/` に CJK フォントを置き `default_theme.tres` を更新。
