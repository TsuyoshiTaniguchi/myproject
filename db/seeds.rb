# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
Admin.find_or_create_by!(email: 'admin@com') do |admin|
  admin.password = 'admin123'
end

# db/seeds.rb
# frozen_string_literal: true
require "securerandom"

puts "── Seeding ──"

# 1. Admin（既存）
Admin.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "admin@example.com")) do |a|
  a.password     = ENV.fetch("ADMIN_PASSWORD", "admin123")
  a.name         = "PortfolioAdmin"
  a.confirmed_at = Time.current
end

# 2. Guest（既存）
GUEST_EMAIL = "guest@example.com"
guest = User.find_or_create_by!(email: GUEST_EMAIL) { |u| u.password = SecureRandom.urlsafe_base64 ; u.name="Guest" }

# ───────────────────────────────────────────────
# 3. デモ用“固定”ユーザー  ← 企業・学校に教える ID
# ───────────────────────────────────────────────
DEMO_EMAIL    = "demo@example.com"
DEMO_PASSWORD = "demo1234"               # 伝える用パス

demo = User.find_or_initialize_by(email: DEMO_EMAIL)
demo.assign_attributes(
  name:               "Demo User",
  password:           DEMO_PASSWORD,
  personal_statement: "ポートフォリオ閲覧用のデモアカウントです。",
  growth_story:       "閲覧者が実際に機能を体験できるように用意しています。"
)
unless demo.profile_image.attached?
  demo.profile_image.attach(
    io: File.open(Rails.root.join("app/assets/images", "user1.jpg")),
    filename: "user1.jpg"
  )
end
demo.save!
puts "Demo user OK (email=#{DEMO_EMAIL} / pw=#{DEMO_PASSWORD})"

# ───────────────────────────────────────────────
# 4. 残り 12 人のサンプルユーザーをバルク生成
#    ※ demo と guest を除外する
# ───────────────────────────────────────────────
images = %w[user2.jpg user3.jpg user4.png user5.jpg user6.png user7.png
           user8.jpg user9.jpg user10.jpg user11.png user12.png user13.png]

names = %w[Ren Aoi Yuto Mei Riku Kana Sora Minato Hina Ryo Kaede Nao]

personal = [
  "アイデアを形にする過程が好き。",
  "人と人をつなぐプロジェクトが得意。",
  "挑戦が日常のスパイス。",
  "失敗は新しいドアを開く鍵だと思う。",
  "誰かの『ありがとう』が何よりの報酬。",
  "好奇心がガソリン。",
  "学び続けることがポリシー。",
  "多様性こそチームの強み。",
  "成果よりプロセスを大事にしたい。",
  "小さな改善を積み上げるのが快感。",
  "困っている人を放っておけない性格。",
  "趣味は写真と散歩。",
  "音楽を聴きながらの作業が最高。"
]

growth = [
  "学生時代の部活で培った粘り強さが今の基盤。",
  "海外ボランティアで『行動する勇気』を学んだ。",
  "スタートアップでの失敗は宝物だった。",
  "読書とアウトプットを 1 セットで続けている。",
  "イベントの運営経験がプロジェクト管理に活きている。",
  "仲間に背中を押されて初登壇した LT が転機。",
  "副業で得た接客経験が顧客視点を育てた。",
  "長期インターンで毎日レビューを受けたのが財産。",
  "国際大会への挑戦で多様な価値観を知った。",
  "師匠と呼べる人との出会いがブーストになった。",
  "毎日 30 分の学習を 3 年続けている。",
  "趣味の写真がクリエイティブ思考を鍛えてくれた。",
  "“作ったものを世に出す” を合言葉にやっている。"
]

names.each_with_index do |name, idx|
  email = "sample#{idx + 1}@example.com"
  user  = User.find_or_initialize_by(email:)
  user.assign_attributes(
    name:               name,
    password:           SecureRandom.base64(10),
    personal_statement: personal[idx % personal.size],
    growth_story:       growth[idx % growth.size]
  )
  unless user.profile_image.attached?
    img = Rails.root.join("app/assets/images", images[idx])
    user.profile_image.attach(io: File.open(img), filename: images[idx])
  end
  user.save!
end
puts " 12 sample users OK"

puts "── Done ──"