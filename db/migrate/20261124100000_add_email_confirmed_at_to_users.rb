class AddEmailConfirmedAtToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :email_confirmed_at, :datetime

    # Accounts created before email confirmation existed are trusted as-is.
    execute "UPDATE users SET email_confirmed_at = created_at"
  end

  def down
    remove_column :users, :email_confirmed_at
  end
end
