# encoding: utf-8
#==============================================================================
# Z_VanillaPassive.rb
# Пассивка Ваниллы (актёр 66) под билд через навыки типа «Призыв» (25).
#
# Что делает:
#   - призывы тоже крадут предметы (таблица добычи 1, как «Кража»);
#   - +30% урона призывов;
#   - +30% к магии (MAT);
#   - +20% к расходу MP на призывы;
#   - призывы срабатывают первыми в ходу (fast_move);
#   - обновляет текст пассивки в NWConst::Library::ACTOR_FIX_ABILITY.
#
# Откат: удалить этот файл. Файлы Data/*.rvdata2 не изменяются.
#==============================================================================

module VanillaPassive
  ACTOR_ID     = 66
  STYPE_SUMMON = 25 # «Призыв»

  # Коды особенностей (NWConst в 128_もんむす総合ベーススクリプト.rb)
  FT_PARAM           = 21
  FT_MULTI_BOOSTER   = 69
  FT_BATTLER_ABILITY = 68
  FT_ADD_STEAL_STYPE = 146
  FT_FAST_MOVE_STYPE = 163

  BOOSTER_SKILL_TYPE      = 7  # «スキルタイプ強化» в MULTI_BOOSTER_ARRAY
  ABILITY_STYPE_COST_RATE = 17 # STYPE_COST_RATE
  PARAM_MAT               = 4  # «魔力» в FEATURE_PARAM_ARRAY

  MAT_RATE     = 1.30
  DAMAGE_BOOST = 0.30
  MP_COST_RATE = 1.20
  STEAL_TABLE  = 1

  ABILITY_TEXT = [
    "Бандитка-Коллекционер",
    "Может использовать навыки \\C[4]Торговли\\C[0], \\C[4]Воровства\\C[0] и \\C[4]Колдовства\\C[0];",
    "Навыки \\C[4]Призыва\\C[0] также крадут предметы;",
    "Навыки \\C[4]Призыва\\C[0] усилены на 30%;",
    "\\C[5]Магия\\C[0] увеличена на 30%;",
    "Затраты MP на навыки \\C[4]Призыва\\C[0] увеличены на 20%;",
    "Навыки \\C[4]Призыва\\C[0] срабатывают первыми в ходу;",
    "150% шанс кражи и выпадения предметов;",
    "Становится сильнее в группе с \"Небесными Бандитками\" на 15% за каждую.",
  ]

  module_function

  # Добавляет особенности актёру. Возвращает true, если применили сейчас.
  def apply(actor)
    return false if actor.nil?
    return false if actor.instance_variable_get(:@vanilla_passive_applied)

    if actor.instance_variable_get(:@add_features).nil?
      actor.instance_variable_set(:@add_features, [])
    end

    actor.add_feature(FT_ADD_STEAL_STYPE, STYPE_SUMMON, STEAL_TABLE)
    actor.add_feature(FT_MULTI_BOOSTER, BOOSTER_SKILL_TYPE, { STYPE_SUMMON => DAMAGE_BOOST })
    actor.add_feature(FT_PARAM, PARAM_MAT, MAT_RATE)
    actor.add_feature(FT_BATTLER_ABILITY, ABILITY_STYPE_COST_RATE,
                      { :type => :MP, :id => STYPE_SUMMON, :rate => MP_COST_RATE })
    actor.add_feature(FT_FAST_MOVE_STYPE, STYPE_SUMMON, true)

    actor.change_features
    actor.setting_feature_data
    actor.instance_variable_set(:@vanilla_passive_applied, true)
    true
  end

  # Подменяет текст «Особенности» у Ваниллы и сбрасывает кэш окна статуса.
  def refresh_text
    return unless defined?(NWConst::Library::ACTOR_FIX_ABILITY)

    NWConst::Library::ACTOR_FIX_ABILITY[ACTOR_ID] = ABILITY_TEXT
    if defined?(SmartStatusModule) && SmartStatusModule.respond_to?(:description_status)
      SmartStatusModule.description_status.delete(ACTOR_ID)
    end
  end

  def patch_database
    return false unless defined?($data_actors) && $data_actors

    applied = apply($data_actors[ACTOR_ID])
    refresh_text
    p "[VanillaPassive] особенности применены" if applied
    applied
  rescue => e
    p "[VanillaPassive] ошибка: #{e.class}: #{e.message}"
    p e.backtrace.first(5)
    false
  end
end

# Текст нужен сразу: таблица определена скриптом Library(Actor).
begin
  VanillaPassive.refresh_text
rescue => e
  p "[VanillaPassive] текст: #{e.class}: #{e.message}"
end

# Особенности применяем после загрузки базы (DataManager читает её при старте).
module DataManager
  class << self
    unless method_defined?(:vanilla_passive_load_normal_database)
      alias_method :vanilla_passive_load_normal_database, :load_normal_database

      def load_normal_database
        vanilla_passive_load_normal_database
        VanillaPassive.patch_database
      end
    end

    unless method_defined?(:vanilla_passive_load_battle_test_database)
      alias_method :vanilla_passive_load_battle_test_database, :load_battle_test_database

      def load_battle_test_database
        vanilla_passive_load_battle_test_database
        VanillaPassive.patch_database
      end
    end
  end
end
