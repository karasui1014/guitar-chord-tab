#!/bin/bash
# ============================================================
#  Guitar Chord TAB を公開用に仕上げる
# ============================================================
#
#  ■ なぜこれが要るか
#  このツールを書き出す環境には、公開版で足している2つが入っていません。
#    1. ヘッダーの「※第三者への無断譲渡・公開はNGです」
#    2. 制作者証明（タイトルを5回連続クリックで © karasui1014 が出る）
#  そのため、書き出したファイルをそのまま公開すると毎回この2つが消えます。
#  このスクリプトが公開前に自動で埋め込むので、書き出し元がどこでも構いません。
#
#  ■ 使い方
#  ダブルクリックするだけ。Downloads の中でいちばん新しい
#  Guitar-Chord-TAB.html を拾って index.html に仕上げます。
#  別のファイルを使いたいときは、そのファイルをこのアイコンにドラッグ＆ドロップ。
#
#  ■ 何度実行しても安全です
#  すでに入っている場合は二重に足しません。
# ============================================================
cd "$(dirname "$0")"

SRC="$1"
if [ -z "$SRC" ]; then
  SRC=$(ls -t ~/Downloads/Guitar-Chord-TAB.html ~/Downloads/Guitar-Chord-TAB*/Guitar-Chord-TAB.html 2>/dev/null | head -1)
fi

if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "❌ 元になるHTMLが見つかりませんでした。"
  echo "   書き出したファイルをこのアイコンにドラッグ＆ドロップしてください。"
  read -n 1 -s -r -p "Enterで閉じます"
  exit 1
fi

echo "元ファイル: $SRC"
echo "           $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$SRC")  $(stat -f '%z' "$SRC") bytes"
echo

python3 - "$SRC" << 'PY'
import sys, shutil, os

src = sys.argv[1]
dst = "index.html"
s = open(src, encoding="utf-8").read()
added = []

# --- 1. 注意書きのCSS ---
if "no-transfer-note{" not in s:
    css = ('.no-transfer-note{margin:0;padding:4px 12px;border:1px solid rgba(78,230,189,.35);'
           'border-radius:999px;background:#4ee6bd12;color:var(--mint);font-size:10.5px;'
           'letter-spacing:.04em;white-space:nowrap}@media(max-width:580px){.no-transfer-note{display:none}}')
    if s.count(".brand{") != 1:
        print("❌ CSSの差し込み位置(.brand{)が見つからないか複数あります。中止しました。"); sys.exit(1)
    s = s.replace(".brand{", css + ".brand{", 1)
    added.append("注意書きのCSS")

# --- 2. 注意書き本体 ---
if "第三者への無断譲渡" not in s:
    if s.count("  </header>") != 1:
        print("❌ 注意書きの差し込み位置(</header>)が見つからないか複数あります。中止しました。"); sys.exit(1)
    s = s.replace("  </header>",
                  '    <p class="no-transfer-note">※第三者への無断譲渡・公開はNGです</p>\n  </header>', 1)
    added.append("無断譲渡の注意書き")

# --- 3. 制作者証明 ---
if "karasui1014" not in s:
    prov = """<!-- 制作者証明（タイトルを5回連続クリックで表示。無断転用時の対抗用） -->
<script>
(function(){
  var n=0,t=0;
  document.addEventListener('click',function(e){
    if(!e.target.closest||!e.target.closest('h1'))return;
    var now=Date.now();
    n=(now-t<1500)?n+1:1;
    t=now;
    if(n>=5){
      n=0;
      var b=document.createElement('div');
      b.textContent='© karasui1014 ／ AI音楽部 Studio 提供ツール ／ '+new Date().toLocaleString('ja-JP');
      b.style.cssText='position:fixed;right:16px;bottom:16px;z-index:99999;background:#161616;color:#fff;padding:12px 16px;border-radius:10px;font:12px/1.6 -apple-system,BlinkMacSystemFont,sans-serif;box-shadow:0 8px 24px rgba(0,0,0,.4);max-width:260px;';
      document.body.appendChild(b);
      setTimeout(function(){b.remove();},6000);
    }
  });
})();
</script>
</body>"""
    if s.count("</body>") != 1:
        print("❌ 制作者証明の差し込み位置(</body>)が見つからないか複数あります。中止しました。"); sys.exit(1)
    s = s.replace("</body>", prov, 1)
    added.append("制作者証明")

if os.path.exists(dst):
    shutil.copyfile(dst, dst + ".bak")

open(dst, "w", encoding="utf-8").write(s)

print("埋め込んだもの: " + ("、".join(added) if added else "なし（すでに全部入っていました）"))
print("書き出し先    : index.html （前の内容は index.html.bak に退避）")
print()
for label, key in [("音源の変化に合わせる", "音源の変化に合わせる"),
                   ("無断譲渡の注意書き", "第三者への無断譲渡"),
                   ("制作者証明", "karasui1014")]:
    print(("  ✅ " if key in s else "  ❌ ") + label)
PY

echo
echo "--- このあと ---"
echo "  1. ローカルで確認する場合:  python3 -m http.server 8080  → http://localhost:8080"
echo "  2. 公開する場合:"
echo "       git add index.html && git commit -m '最新ビルドへ更新' && git push"
echo
read -n 1 -s -r -p "Enterで閉じます"
