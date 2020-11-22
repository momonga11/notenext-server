class CreateNotes < ActiveRecord::Migration[6.0]
  def change
    create_table :notes do |t|
      t.references :project, null: false, foreign_key: true
      t.references :folder, null: false, foreign_key: true
      t.string :title
      t.text :text
      t.text :htmltext
      t.integer :lock_version, default: 0

      t.timestamps
    end
  end
end
