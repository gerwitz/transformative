Sequel.migration do
  change do
    create_table(:flows) do
      primary_key :id
      foreign_key :site_id, :sites
      foreign_key :store_id, :stores
      foreign_key :media_store_id, :stores
      Int :post_type
      TrueClass :allow_media
      TrueClass :allow_meta
      String :name, size: 140
      String :url_template
      String :content_template, text: true
    end
  end
end
