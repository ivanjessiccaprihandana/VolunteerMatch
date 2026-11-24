# Categories become a fixed list. Existing free-text values are mapped to the
# matching list entry (case-insensitive), otherwise to "Lainnya".
class NormalizeEventCategories < ActiveRecord::Migration[8.1]
  CATEGORIES = %w[Lingkungan Pendidikan Kesehatan Sosial Bencana Hewan Lainnya].freeze

  def up
    CATEGORIES.each do |category|
      execute <<~SQL
        UPDATE volunteer_events
        SET category = #{quote(category)}
        WHERE lower(trim(category)) = #{quote(category.downcase)}
      SQL
    end

    execute <<~SQL
      UPDATE volunteer_events
      SET category = 'Lainnya'
      WHERE category NOT IN (#{CATEGORIES.map { |c| quote(c) }.join(", ")})
    SQL

    add_index :volunteer_events, :category
  end

  def down
    remove_index :volunteer_events, :category
  end

  private

  def quote(value)
    connection.quote(value)
  end
end
