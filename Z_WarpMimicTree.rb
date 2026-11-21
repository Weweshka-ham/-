# encoding: utf-8
#==============================================================================
# Z_WarpMimicTree.rb
# Телепорт к дереву — входу в Остров Мимиков (карта 2, 434, 328).
#
# Что делает:
#   - добавляет место «Остров Мимиков (дерево)» в конец списка NWConst::Warp::Places;
#   - разблокирует его — переключатель 5142 (WARP_OPEN_BASE + индекс 141).
#   - переключатель включается при старте игры и при открытии меню варпа,
#     поэтому место видно и в старых сохранениях.
#
# Откат: удалить этот файл. Файлы в D:\ не изменяются.
#==============================================================================

module WarpMimicTree
  MAP_ID   = 2
  MAP_X    = 434
  MAP_Y    = 328
  NAME     = "Остров Мимиков (дерево)"
  CATEGORY = :Сингулярность
  INDEX    = 141  # новая запись дописывается в конец Places (сейчас 141 записей)
  SWITCH   = 5001 + INDEX # WARP_OPEN_BASE + 141

  module_function

  def add_place
    return if NWConst::Warp::Places.any? do |p|
      p[:map_id] == MAP_ID && p[:x] == MAP_X && p[:y] == MAP_Y
    end

    NWConst::Warp::Places << {
      :name        => NAME,
      :map_id      => MAP_ID,
      :x           => MAP_X,
      :y           => MAP_Y,
      :category    => CATEGORY,
      :index       => INDEX,
      :v2location  => [2, 284, 274],
      :v3location  => [2, 297, 356],
    }
  end

  def unlock_switch
    return unless defined?($game_switches) && $game_switches
    $game_switches[SWITCH] = true
  end

  def apply
    add_place
    unlock_switch
  end
end

# Places уже определён в 196_IDReserve.rb, так что можно применить сразу.
begin
  WarpMimicTree.apply
rescue => e
  p "[WarpMimicTree] ошибка при загрузке патча: #{e.class}: #{e.message}"
end

# При перезагрузке базы мод-менеджером — применить ещё раз (запись не дублируется).
module DataManager
  class << self
    unless method_defined?(:wmt_load_normal_database)
      alias_method :wmt_load_normal_database, :load_normal_database
      def load_normal_database
        wmt_load_normal_database
        WarpMimicTree.add_place
      end
    end

    unless method_defined?(:wmt_load_battle_test_database)
      alias_method :wmt_load_battle_test_database, :load_battle_test_database
      def load_battle_test_database
        wmt_load_battle_test_database
        WarpMimicTree.add_place
      end
    end

    unless method_defined?(:wmt_create_game_objects)
      alias_method :wmt_create_game_objects, :create_game_objects
      def create_game_objects
        wmt_create_game_objects
        WarpMimicTree.unlock_switch
      end
    end
  end
end

# Старые сохранения не знают про переключатель 5142 — включаем его при входе в меню варпа,
# чтобы место было видно в любом сейве.
class Scene_Warp < Scene_MenuBase
  unless method_defined?(:wmt_start)
    alias_method :wmt_start, :start
    def start
      WarpMimicTree.unlock_switch
      wmt_start
    end
  end
end
