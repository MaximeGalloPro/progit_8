class AddPhoneNumberToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :bigint unless column_exists?(:users, :phone_number)
  end
end
