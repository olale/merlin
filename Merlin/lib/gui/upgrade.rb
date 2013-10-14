# -*- coding: utf-8 -*-
require 'pathname'
$LOAD_PATH.unshift((Pathname.new($0)+"../../../").to_s)
require 'init'
require 'gui'
require 'db'
require 'config/build'

module TC::GUI
  class UpgradeGUI < BaseGUI

    BaseGUI.create_db_action = lambda do 
      action = TC::DbUpgrade.create Conf, Conf.product
      action.basedir=TC.upgrade_dir_dest(Conf.product).to_win_path
      action
    end
    BaseGUI.use_backup=true
    BaseGUI.action_name="Uppdatera"
    BaseGUI.progress_caption=lambda { "Uppdaterar #{Conf.current_setting}" }
    BaseGUI.confirm_question=lambda { "Uppdatera #{Conf.current_setting}?" }
    BaseGUI.aborted_action_message="Fel under uppdateringen"
  end

end

if $0 == __FILE__
  TC::GUI::UpgradeGUI.app(title: "Databasuppdateringsverktyg för #{TC::GUI::Conf.product_name} #{TC::Conf::Build.version(TC::GUI::Conf.product)}", 
            width: 400, 
            height: 600)
end
