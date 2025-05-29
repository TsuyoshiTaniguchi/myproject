class AddPolymorphicAssociationToLikes < ActiveRecord::Migration[6.1]
  def change
    remove_column :likes, :post_id, if_exists: true

    unless column_exists?(:likes, :likeable_id) && column_exists?(:likes, :likeable_type)
      add_reference :likes, :likeable, polymorphic: true, index: true
    end

    remove_foreign_key :likes, :posts, column: :likeable_id
    add_foreign_key :likes, :users, column: :likeable_id
  end
end