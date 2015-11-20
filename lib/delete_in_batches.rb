require "delete_in_batches/version"
require "active_record"

module DeleteInBatches
  def delete_in_batches(options = {})
    batch_size = options[:batch_size] || 10000

    # TODO dry
    pk = "#{quoted_table_name}.#{quoted_primary_key}"
    subquery = -> { select(pk).limit(batch_size).to_sql }
    sql =
      if connection.respond_to?(:unprepared_statement)
        # ActiveRecord 4
        connection.unprepared_statement &subquery
      else
        subquery.call
      end

    while connection.delete("DELETE FROM #{quoted_table_name} WHERE #{pk} IN (#{sql})") == batch_size
      yield if block_given?
    end
  end
end

ActiveRecord::Base.send :extend, DeleteInBatches
