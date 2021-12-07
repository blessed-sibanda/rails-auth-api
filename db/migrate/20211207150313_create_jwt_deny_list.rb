class CreateJwtDenyList < ActiveRecord::Migration[6.1]
  def change
    create_table :jwt_deny_list do |t|
      t.string :jti
      t.datetime :expired_at

      t.timestamps
    end
    add_index :jwt_deny_list, :jti
  end
end
