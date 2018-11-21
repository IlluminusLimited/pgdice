# frozen_string_literal: true

module PgDice
  # Helper used to manipulate date objects
  module DateHelper
    def pad_date(numbers)
      return numbers if numbers.size == 8

      case numbers.size
      when 6
        return numbers + '01'
      when 4
        return numbers + '0101'
      else
        raise ArgumentError, "Invalid date. Cannot parse date from #{numbers}"
      end
    end

    def truncate_date(date, period)
      case period
      when 'year'
        Date.parse("#{date.year}0101")
      when 'month'
        Date.parse("#{date.year}#{date.month}01")
      when 'day'
        date
      else
        raise ArgumentError, "Invalid date. Cannot parse date from #{date}"
      end
    end

    def safe_date_builder(table_name)
      matches = table_name.match(/\d+/)
      raise ArgumentError, "Invalid date. Cannot parse date from #{table_name}" unless matches

      Date.parse(pad_date(matches[0]))
    end
  end
end
