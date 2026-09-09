class CreateLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :locations do |t|
      t.string :ip_address
      t.string :hostname
      t.string :address_type
      t.string :country_code
      t.string :country_name
      t.string :region_name
      t.string :city
      t.string :zip_code
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.json :raw_response
      t.timestamps
    end
    add_index :locations, :country_code
  end
end