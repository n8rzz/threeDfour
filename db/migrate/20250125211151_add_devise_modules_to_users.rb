class AddDeviseModulesToUsers < ActiveRecord::Migration[8.0]
  def change
    ## Confirmable
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    ## Lockable
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime

    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token, unique: true

    # Mark existing users as confirmed
    User.update_all(confirmed_at: Time.current)
  end
end
