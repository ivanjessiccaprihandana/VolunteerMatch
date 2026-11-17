class CreateOrganizationProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :organization_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :organization_name, null: false
      t.string :phone
      t.string :city
      t.text :description
      t.string :website
      t.boolean :verified, null: false, default: false

      t.timestamps
    end
  end
end
