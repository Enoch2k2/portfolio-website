class CreateOauthIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_integrations do |t|
      t.string :provider, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.string :external_account_id
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :oauth_integrations, :provider, unique: true
    add_index :oauth_integrations, :active
  end
end
