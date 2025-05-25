class AddCodeSnippetToPosts < ActiveRecord::Migration[6.1]
  def change
    add_column :posts, :code_snippet, :text
  end
end
