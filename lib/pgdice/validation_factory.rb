module PgDice

  class ValidationFactory
    extend Forwardable
    def_delegator :@configuration, :logger, :database_connection, :approved_tables

    def initalize(configuration = PgDice::Configuration.new)
       @configuration = configuration
    end

    def call
      PgDice::Validation.new(logger, database_connection, approved_tables)
    end
  end
end