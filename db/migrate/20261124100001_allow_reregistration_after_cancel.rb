# A volunteer who cancelled may register again. Only one *active*
# (non-cancelled) registration per volunteer and event is allowed.
class AllowReregistrationAfterCancel < ActiveRecord::Migration[8.1]
  CANCELLED = 3

  def change
    remove_index :event_registrations,
                 %i[volunteer_event_id volunteer_id],
                 unique: true,
                 name: "index_event_registrations_on_event_and_volunteer"

    add_index :event_registrations,
              %i[volunteer_event_id volunteer_id],
              unique: true,
              where: "status <> #{CANCELLED}",
              name: "index_event_registrations_on_active_event_and_volunteer"
  end
end
