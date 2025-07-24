cat << 'EOF' > docs/scripts/normalize_models.sh
#!/usr/bin/env bash
# 入力: docs/schema_block.tsv
# 出力: docs/models_normalized.tsv

INPUT=docs/schema_block.tsv
OUTPUT=docs/models_normalized.tsv

awk -F '\t' 'BEGIN {
  OFS = "\t"
}
NR==1 {
  # 1行目はヘッダをそのまま
  print
  next
}
{
  # 1～10列を必ず出力
  for (i = 1; i <= 10; i++) {
    field = (i <= NF ? $i : "")
    printf("%s%s", field, (i < 10 ? OFS : ""))
  }
  printf("\n")
}' "$INPUT" > "$OUTPUT"

echo "▶ 正規化済みTSVを作成しました: $OUTPUT"
EOF