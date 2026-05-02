# Godot UI Snippets

再利用可能な Godot 4.x 向け UI スニペット集。**ダイアログ・ボタン・アニメーション対応の背景／枠**をまとめたアドオンと、動作確認用デモシーンが入っています。

> 背景や枠は `SpriteFrames` を受け取るので、**1 枚の静止画**でも **複数枚のフレームアニメ**でも同じ API で扱えます。

## クイックスタート

1. リポジトリを clone し、Godot 4.3+ で `project.godot` を開く。
2. メインシーン (`demos/main.tscn`) が自動再生され、上のボタンから 3 つのデモ (AnimatedPanel / Buttons / Dialogs) を切り替えられる。

別プロジェクトで使う場合は `addons/ui_snippets/` フォルダごとコピーし、Project Settings → Plugins で `UI Snippets` を有効化してください。スニペットはすべて `class_name UISnip*` で登録されています。

## ディレクトリ構成

```
addons/ui_snippets/
  core/
    animated_panel.gd / .tscn   # 背景＋枠の二層 NinePatchRect。SpriteFrames で駆動
    frame_animator.gd           # Texture2D[] を fps で送る軽量ヘルパ (RefCounted)
    ui_animator.gd              # static helper: fade / slide / pop / shake / typewriter
    ui_state.gd                 # enum 集約
  buttons/
    animated_button.gd / .tscn  # hover/press/focus/disabled で SpriteFrames + scale 切替
    icon_button.gd              # AnimatedButton + 左アイコン
    toggle_button.gd            # ON/OFF で frames_idle を切替
    menu_button.gd              # RPG 風カーソル付きの縦メニュー
  dialogs/
    base_dialog.gd / .tscn      # CanvasLayer + Backdrop + AnimatedPanel + AnimationPlayer
    message_dialog.*            # Typewriter 表示
    confirm_dialog.*            # Yes/No
    choice_dialog.*             # N 択
    input_dialog.*              # 1 行テキスト入力
    progress_dialog.*           # ProgressBar + 任意の Cancel
    toast.*                     # 自動消滅、軽量、非モーダル
assets/ui/
  theme/default_theme.tres      # フォント色などの最小テーマ
  placeholder/                  # 差し替え前提のサンプル SVG + SpriteFrames
demos/
  main.tscn                     # ランディング (デモ切替)
  demo_animated_panel.tscn
  demo_buttons.tscn
  demo_dialogs.tscn
```

## 主要 API

### `UISnipAnimatedPanel`

Control 派生。背景レイヤと枠レイヤをそれぞれ `NinePatchRect` でレンダリングし、各々独立した `SpriteFrames` で駆動します。フレーム数 1 なら静止扱い、N なら自動アニメ。

```gdscript
@export var background_frames: SpriteFrames
@export var background_animation: StringName = &"default"
@export var border_frames: SpriteFrames
@export var border_animation: StringName = &"default"
@export var fps_override: float = 0.0           # 0 なら SpriteFrames の speed を使用
@export var bg_patch_margin: int = 16
@export var border_patch_margin: int = 16
@export var paused: bool = false

func play() -> void
func stop() -> void
func set_frame(i: int) -> void
```

### `UISnipAnimator`（static）

Tween を返すユーティリティ。呼び出し側で `await tween.finished` できます。

- `fade_in / fade_out`
- `slide_in(node, from_dir) / slide_out(node, to_dir)`
- `pop_in / pop_out`
- `shake`
- `typewriter(label, text, cps)` — `Label` / `RichTextLabel` の `visible_ratio` を Tween

### `UISnipAnimatedButton`

`Button` 派生。背景に `UISnipAnimatedPanel` を内包し、状態ごとに `frames_idle / frames_hover / frames_press / frames_focus / frames_disabled` を切り替え、`scale` を Tween。

### Dialogs

`UISnipBaseDialog` を継承した各ダイアログは静的ヘルパ `popup(parent, ...)` で 1 行で開けます。`await` で結果を受けられます。

```gdscript
# Message
await UISnipMessageDialog.popup(self, "Hello")

# Confirm
var ok: bool = await UISnipConfirmDialog.popup(self, "削除しますか?")

# Choice
var idx: int = await UISnipChoiceDialog.popup(self, "難易度:", PackedStringArray(["Easy", "Hard"]))

# Input
var name: Variant = await UISnipInputDialog.popup(self, "お名前:", "Player")

# Progress
var dlg := UISnipProgressDialog.popup(self, "Loading...", true)
dlg.set_progress(0.5)

# Toast
UISnipToast.show_toast(self, "Saved!")
```

`base_dialog` の挙動:
- `is_modal`: バックドロップで背景クリックを遮断するか
- `close_on_backdrop`: 背景クリックで閉じるか
- `close_on_esc`: ESC で閉じるか
- 開閉アニメは `Root/AnimationPlayer` に `open` / `close` を追加すれば優先される。空なら `UISnipAnimator.pop_in / pop_out` がフォールバック

## 画像差し替え

`assets/ui/placeholder/` のサンプルはあくまで動作確認用です。

1. 自前の画像を `assets/` 以下に置く（PNG / SVG どちらでも可）。
2. `SpriteFrames` リソースを 1 つ作成し、フレームを並べる（1 枚でも複数枚でも可）。
3. インスペクタで `AnimatedPanel.background_frames` などにドラッグ&ドロップ。

> 9-slice 用に画像のコーナー保護領域を `bg_patch_margin` / `border_patch_margin` で指定してください。

## Godot バージョン

Godot 4.3 以上を想定（`config/features` に `4.3` を指定）。`@export var x: SpriteFrames` 形式の型付きエクスポート、`Tween` API、`@tool` のインスペクタプレビューに依存します。

## ライセンス

MIT (LICENSE 参照)。プレースホルダ画像も同条件です。
