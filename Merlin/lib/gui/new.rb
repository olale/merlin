# -*- coding: utf-8 -*-
require 'pathname'
$LOAD_PATH.unshift((Pathname.new($0)+"../../../").to_s)
require 'init'
require 'gui'
require 'db'
require 'config/build'

module TC::GUI
  class NewDBGUI < BaseGUI

    BaseGUI.create_db_action = lambda do 
      db_action=TC::Create.new Conf, Conf.product
      db_action.dump_root=TC.new_dir_dest(Conf.product).to_win_path
      db_action
    end
    BaseGUI.action_name="Installera"
    BaseGUI.progress_caption=lambda { "Installerar #{Conf.current_setting}" }
    BaseGUI.confirm_question=lambda { "Installera #{Conf.current_setting}?" }
    BaseGUI.aborted_action_message="Fel under installationen"
  end

end

if $0 == __FILE__
  TC::GUI::NewDBGUI.app(title: "Databasinstallation för #{TC::GUI::Conf.product_name} #{TC::Conf::Build.version(TC::GUI::Conf.product)}", 
            width: 400, 
            height: 500)
end
