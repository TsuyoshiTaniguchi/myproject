#!/usr/bin/env ruby
# docs/scripts/normalize_models_csv.rb

require 'csv'

INPUT  = 'docs/schema_block.tsv'
OUTPUT = 'docs/models_normalized.csv'

lines = File.read(INPUT, encoding: 'utf-8').lines
current_table = nil

CSV.open(OUTPUT, 'wb', force_quotes: true) do |csv|
  # ヘッダ
  csv << %w[Table カラム名 カラム説明 PK FK データ型 NOT_NULL AUTO_INCREMENT INDEX DEFAULT]

  lines.each do |line|
    line.chomp!
    # テーブル行
    if line =~ /^Table[:\s]+(\w+)/
      current_table = $1
      next
    end
    # ヘッダ行 or 空行はスキップ
    next if line.start_with?('カラム名') || line.strip.empty?

    cols = line.split("\t", -1)
    row  = ([current_table] + cols).first(10)
    # 足りない列は空文字で埋め
    row.fill('', row.size...10)
    csv << row
  end
end

puts "▶ 完成: #{OUTPUT}"