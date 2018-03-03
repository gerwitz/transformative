Sequel.migration do
  change do
    create_table(:terminals) do
      primary_key :id
      foreign_key :site_id, :sites
      String :type_id, null: false
      String :location
      String :user
      String :key
    end
  end
end
