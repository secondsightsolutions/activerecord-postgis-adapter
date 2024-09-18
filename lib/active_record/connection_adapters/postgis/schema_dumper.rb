# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module PostGIS
      class SchemaDumper < PostgreSQL::SchemaDumper # :nodoc:
        private
        # # Overridden in order to build a list of tables with their schema prefix
        # # (rest of the method is the same).
        # https://github.com/rails/rails/blob/main/activerecord/lib/active_record/schema_dumper.rb
        def tables(stream)
          table_query = <<-SQL
            SELECT schemaname, tablename
            FROM pg_tables
            WHERE schemaname = ANY(current_schemas(false))
          SQL

          sorted_tables = @connection.exec_query(table_query, 'SCHEMA').map do |table|
            "#{table['schemaname']}.#{table['tablename']}"
          end.sort

          not_ignored_tables = sorted_tables.reject { |table_name| ignored?(table_name.split('.')[1]) }
  
          not_ignored_tables.each do |table_name|
            table(table_name, stream)
          end
  
          # dump foreign keys at the end to make sure all dependent tables exist.
          if @connection.use_foreign_keys?
            not_ignored_tables.each do |tbl|
              foreign_keys(tbl, stream)
            end
          end
        end
      end
    end
  end
end
