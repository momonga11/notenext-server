class DeleteColumnToUserSample < ActiveRecord::Migration[6.1]
  def up
    remove_column :user_samples, :updated_at, :datetime
    remove_column :user_samples, :created_at, :datetime
    remove_column :user_samples, :payout, :boolean
  end

  def down
    add_column :user_samples, :payout, :boolean
    add_column :user_samples, :created_at, :datetime, null: false, default: -> { 'now()' }
    add_column :user_samples, :updated_at, :datetime, null: false, default: -> { 'now()' }

    change_column_default :user_samples, :created_at, nil
    change_column_default :user_samples, :updated_at, nil
  end
end
