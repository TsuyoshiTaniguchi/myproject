class AddConfirmableToUsers < ActiveRecord::Migration[6.1]
  # Devise のガイド推奨
  def change
    add_column :users, :confirmation_token,   :string
    add_column :users, :confirmed_at,         :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email,    :string
    add_index  :users, :confirmation_token, unique: true

    # 既存レコードをまとめて「確認済み」にする
    reversible do |dir|
      dir.up { User.update_all confirmed_at: Time.current }
    end
  end
end
