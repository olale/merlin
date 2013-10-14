
module TC

  # Parser for Wmic output, to extract information about packages to
  # uninstall from a system
  class WmicParser

    attr_accessor :product_list

    @@package_pattern = /c:\\Windows\\Installer\\\w+\.msi/i

    # +product_list+ is a list of strings, read from a product list produced by
    def initialize product_list
      @product_list=product_list.collect do |l|
        begin
          l.encode!("US-ASCII")
        rescue Encoding::UndefinedConversionError
          l=""
        end
        l
      end
    end

    def self.get_products_command
      "wmic product list"
    end

    def get_msi(product_name)
      line=product_list.find do |l| 
        l.include? product_name
      end
      match = @@package_pattern.match(line)
      match ? match.to_s : nil
    end

  end

end
