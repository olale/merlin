# -*- coding: iso-8859-1 -*-
require 'common'
require 'pathname'
require 'command'
require 'tcfileutils'
require 'rake' # FileList
require 'config/sql'
require 'config/database'
require 'config/command'
require 'dsl'
require 'active_record'
require 'ostruct'
require 'tempfile' 

require 'diff/lcs'
require 'diff/lcs/string'
require 'diff/lcs/array'

module ActiveModel::Validations::HelperMethods
  # Hack to define this module here, but it seems necessary to have it
  # defined prior to use for active_record > 3.0.3 when used outside Rails.

  # See http://www.ruby-forum.com/topic/4408385
end

# This gem requires the existence of the HelperMethods module above
require 'composite_primary_keys'

require 'db/backup'
require 'db/compare'
require 'db/create'
require 'db/dumper'
require 'db/multidb'
require 'db/upgrade'
require 'db/restore'
