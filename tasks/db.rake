namespace :db do
  namespace :schema do
    desc "Show the model schema (optional params: only=model1,model2,...)"
    task :show => :environment do
      begin
        only = []
        only = ENV["only"].split(",").map { |c| eval(c.classify) } if ENV["only"]
        models = Dir.glob("#{Rails.root}/app/models/*.rb").map { |m| eval(File.basename(m, ".rb").classify) }
        models.reject! { |m| !only.member?(m) } unless only.empty?
        models.each do |m|
          DbUtils.print_table(m)
          puts
        end
      rescue NameError => e
        puts "There is no model named \"#{e.missing_name}\""
      end
    end
    task :show => "db:schema:dump"
  end
end

module DbUtils
  HEADERS = {
    :name => "Name", 
    :default => "Default", 
    :type => "Type",
    :limit => "Limit", 
    :null => "Null", 
    :sql_type => "SQL Type",
    :precision => "Precision", 
    :scale => "Scale", 
    :primary => "Primary Key"
  }
  FIELDS = [:name, :type, :sql_type, :limit, :default, :null, :precision, :scale, :primary]
    
  class << self
    def print_table(model)
      print_header(model)
      attributes = attributes(model)
      cell_widths = {}
      HEADERS.each_key { |k| cell_widths[k] = longest(attributes.map { |a| a[k].to_s }.unshift(HEADERS[k])) }
      
      print_divider(cell_widths)
      FIELDS.each_with_index do |f, i|
        printf("%s", cell(HEADERS[f], cell_widths[f], i == 0, true))
      end
      puts
      print_divider(cell_widths)
      
      attributes.each do |a|
        FIELDS.each_with_index do |f, i|
          printf("%s", cell(a[f].to_s, cell_widths[f], i == 0, true))
        end
        puts
      end
      print_divider(cell_widths)
    end
    
    def print_divider(cell_widths)
      divider = ""
      FIELDS.each_with_index do |f, i|
        divider << ((i==0) ? "+" : "") + "-" * (cell_widths[f] + 2) + "+"
      end
      puts divider
    end
    
    def print_header(model)
      puts " #{model.name}"
    end
    
    def attributes(model)
      model.columns.map do |col|
        { :name => col.name, 
          :default => col.default, 
          :type => col.type,
          :limit => col.limit, 
          :null => col.null, 
          :sql_type => col.sql_type,
          :precision => col.precision, 
          :scale => col.scale, 
          :primary => col.primary
        }
      end
    end

    def longest(words)
      words.inject(0) { |longest, word| (word.length > longest) ? word.length : longest }
    end

    def cell(text, width, left_bar=true, right_bar=true)
      (left_bar ? "| " : " ") + text + (" " * (width-text.length)) + (right_bar ? " |" : " ")
    end
  end
end