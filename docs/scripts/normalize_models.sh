#!/usr/bin/env bash
# docs/scripts/normalize_models.sh
# 空白 or タブを区切りとみなし、必ず10列にして出力

INPUT=docs/schema_block.tsv
OUTPUT=docs/models_normalized.tsv

awk '
  BEGIN {
    # 出力ヘッダ
    OFS = "\t"
    print "Table","カラム名","カラム説明","PK","FK","データ型","NOT_NULL","AUTO_INCREMENT","INDEX","DEFAULT"
  }
  # 2行目以降を処理
  NR > 1 {
    # FS="[ \t]+" により、「空白1つ以上 or タブ1つ以上」で分割
    for (i = 1; i <= 10; i++) {
      # i番目のフィールドがあればそれを、なければ空文字を出力
      printf("%s%s", ($i? $i : ""), (i<10? OFS : ""))
    }
    print ""
  }
' FS='[ \t]+' "$INPUT" > "$OUTPUT"

echo "▶ 完成: $OUTPUT"