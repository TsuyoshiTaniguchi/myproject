exit
# db/seeds.rb
# frozen_string_literal: true
require "securerandom"
I18n.default_locale = :en

puts "── Seeding ──"


# 1. Admin

# ENV または Rails.credentials から一度だけ取得
admin_email    = ENV.fetch("ADMIN_EMAIL")    { Rails.application.credentials.dig(:admin, :email) }
admin_password = ENV.fetch("ADMIN_PASSWORD") { Rails.application.credentials.dig(:admin, :password) }

admin = User.find_or_initialize_by(email: admin_email)

if admin.new_record?
  admin.assign_attributes(
    password: admin_password,
    name:     "管理者",
    role:     :admin
  )
  admin.skip_confirmation! if admin.respond_to?(:skip_confirmation!)
  admin.save!
  puts "✅ Admin user created (#{admin_email})"
else
  # ENV 変更時にパスワードも上書きしたいならここで update! する
  puts "⚪️ Admin already exists (#{admin_email})"
end


# ─────────────────────────────
# 2. Guest
# ─────────────────────────────
guest = User.find_or_initialize_by(email: "guest@example.com")

guest.update!(
  password: SecureRandom.urlsafe_base64, # 何度 seed を流してもランダム
  name:     "Guest",
  role:     :guest                       # ここが肝：必ず guest 役割にする
)

guest.skip_confirmation! if guest.respond_to?(:skip_confirmation!)

puts "✅ Guest user ensured  (id=#{guest.id})"

# ─────────────────────────────
# 3. Demo（ポートフォリオ公開用）
# ─────────────────────────────
demo = User.find_or_initialize_by(email: "demo@example.com")
demo.assign_attributes(
  # ← 必ずここに email を明示的に書く
  email:              "demo@example.com",
  name:               "Demo User",
  password:           "demo1234",
  password_confirmation: "demo1234",   # Devise で必須なら追加
  personal_statement: "ポートフォリオ閲覧用のデモアカウントです。",
  growth_story:       "閲覧者が実際に機能を体験できるように用意しています。"
)

demo.skip_confirmation! if demo.respond_to?(:skip_confirmation!)

unless demo.profile_image.attached?
  demo.profile_image.attach(
    io:       File.open(Rails.root.join("app/assets/images", "user1.jpg")),
    filename: "user1.jpg"
  )
end

demo.save!   # ← ここで email, password がセットされていれば通る
puts "Demo user OK (email=demo@example.com / pw=demo1234)"


puts "── Done ──"
