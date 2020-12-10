class CreateUsersProjects < ActiveRecord::Migration[6.0]
  def change
    create_table :users_projects, primary_key: %i[user_id project_id] do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.boolean :is_owner, null: false
      t.timestamps
    end
  end
end
