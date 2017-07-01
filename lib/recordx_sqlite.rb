#!/usr/bin/env ruby

# file: recordx_sqlite.rb

require 'sqlite3'
require 'recordx'


class RecordxSqlite

  def initialize(dbfile, table: '', primary_key: :id, pk: primary_key, 
                 sql: nil)
        
    @db = SQLite3::Database.new dbfile

    @db.results_as_hash = true
    
    if table.is_a? String then
      
      @table, @primary_key = table, pk.to_sym
      
    elsif table.is_a? Hash 
      
      h = table
      @table = h.keys.first
      @primary_key = h[@table].keys.first
      
      create_table(@table, h[@table]) if @db.table_info(@table).empty?
            
    end
    
    @sql =  sql || 'select * from ' + @table.to_s
    
    @a = nil
    
  end

  # note: when using method all() you will need to call method refresh() 
  # first if a record had recently been added since the recordset was loaded
  #
  def all()    
    query(@sql) unless @a
    @a
  end

  def create(h={})
    
    fields = h.keys
    values = h.values

    sql = "INSERT INTO #{@table} (#{fields.join(', ')})
    VALUES (#{(['?'] * fields.length).join(', ')})"

    @db.execute(sql, values)
    
     :create
  end
  
  def delete(id)
    
    sql = "DELETE FROM #{@table} WHERE #{@primary_key}='#{id}'"
    @db.execute sql
    
    :delete
  end

  def find(id)

    query(@sql) unless @a
    @a.find {|x| x.method(@primary_key).call == id}
    
  end

  def query(sql=@sql)
    
    @sql = sql
    rs = @db.query sql
    
    @a = rs.map do |h| 
      h2 = h.inject({}) {|r, x| k, v = x; r.merge(k.to_sym => v)}
      RecordX.new(h2, self, h2[@primary_key]) 
    end    
    
  end  

  def refresh()
    query(@sql)
    'refreshed'
  end

  def update(id, h={})

    col, value = h.to_a.first
    return if col == @primary_key

s = "
UPDATE #{@table}
SET #{col}='#{value}'
WHERE #{@primary_key.to_s}='#{id}';"

    @db.execute(s)

  end

  private

  def create_table(name, cols)
    
    fields = cols.map do |k,v|

      types = { string: :text, integer: :int, float: :real,   date: :date }
      type = types[v.class.to_s.downcase.to_sym].to_s.upcase
      "%s %s" % [k.to_s, type]

    end

    sql = "CREATE TABLE %s (\n  %s PRIMARY KEY NOT NULL,\n  %s\n);" % 
      [name, fields.first, fields[1..-1].join(",\n  ")]

    @db.execute sql
    
  end  

end