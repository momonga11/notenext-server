class CreateProjects < ActiveRecord::Migration[6.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.integer :lock_version, default: 0

      t.timestamps
    end
  end
end
