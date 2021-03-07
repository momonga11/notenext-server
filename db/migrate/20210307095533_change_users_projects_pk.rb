class ChangeUsersProjectsPk < ActiveRecord::Migration[6.0]
  def change
    reversible do |change|
      change.up do
        execute 'ALTER TABLE users_projects DROP PRIMARY KEY'
      end

      change.down do
        execute 'ALTER TABLE users_projects ADD PRIMARY KEY (user_id, project_id)'
      end
    end
    add_column :users_projects, :id, :primary_key, first: true
  end
end
