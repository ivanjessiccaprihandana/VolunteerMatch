class CreateEventRegistrations < ActiveRecord::Migration[7.0]
  def change
    create_table :event_registrations do |t|
      t.references :volunteer,
                   null: false,
                   foreign_key: { to_table: :users }
      t.references :volunteer_event,
                   null: false,
                   foreign_key: true
      t.text :motivation, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :event_registrations,
              %i[volunteer_event_id volunteer_id],
              unique: true,
              name: "index_event_registrations_on_event_and_volunteer"
  end
end
