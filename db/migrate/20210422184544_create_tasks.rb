class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :note, null: false, foreign_key: true
      t.date :date_to
      t.boolean :completed, null: false, default: 0
      t.integer :lock_version, default: 0

      t.timestamps
    end
  end
end
