require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

#  this is the method that grabs us the table name we want to query for column names
# to_s changes it into a string
# downcases (or "un-capitalizes")
#  #pluralize method is provided to us by the active_support/inflector code library, required at the top of lib/song.rb
  def self.table_name
    self.to_s.downcase.pluralize
  end

#  get information about each column from our table
  def self.column_names
    DB[:conn].results_as_hash = true
#  paragma and #table_name to access the name of the table we are querying
    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    # We call #compact on that just to be safe and get rid of any nil values that may end up in our collection.
    column_names.compact
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym #convert the column name string into a symbol with the #to_sym
  end
# So, we need to define our #initialize method to take in a hash of named,
#  or keyword, arguments. However, we don't want to explicitly name those arguments.
  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end
# save is an instance method hence cannot use class method directly

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

# Abstracting the Table Name which is a class method for instance method save
  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  # Abstracting the Column Names
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



