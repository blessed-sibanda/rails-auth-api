class AddExpToJwtDenyList < ActiveRecord::Migration[6.1]
  def change
    add_column :jwt_deny_list, :exp, :string
  end
end
