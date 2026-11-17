class CreateVolunteerProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :volunteer_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :phone
      t.string :city
      t.text :bio
      t.text :skills
      t.string :availability

      t.timestamps
    end
  end
end
