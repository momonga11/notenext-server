class CreateUserSamples < ActiveRecord::Migration[6.0]
  def change
    create_table :user_samples do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :payout

      t.timestamps
    end
  end
end
