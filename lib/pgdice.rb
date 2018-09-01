# frozen_string_literal: true

require 'open3'
require 'pgdice/version'
require 'pgdice/configuration'
require 'pgdice/pg_slice_manager'
require 'pgdice/partition_manager'
require 'pgdice/exceptions/pg_dice_error'
require 'pgdice/exceptions/pg_slice_error'
require 'pgdice/exceptions/illegal_table_error'
