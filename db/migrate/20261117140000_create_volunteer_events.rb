class CreateVolunteerEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :volunteer_events do |t|
      t.references :organization,
                   null: false,
                   foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description, null: false
      t.string :category, null: false
      t.string :location, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.datetime :registration_deadline, null: false
      t.integer :capacity, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :volunteer_events, %i[status starts_at]
  end
end
