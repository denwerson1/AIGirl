PATCH 001 (Traits + Thoughts + Autotune Policy)
=================================================

Что добавляет:
1) 136 новых параметров (trait.* / state.* / voice.*) в dbo.ParameterDefinitions
2) Таблицы:
   - dbo.ParameterThoughtTemplates (мысли рядом с ползунком)
   - dbo.CharacterParameterHistory (история изменений + тренд)
   - dbo.ParameterAutoTunePolicy (политика автокоррекции)
3) Начальные значения для AI.Ника и AI.Иша (разные личности)
4) Backend API обновлён:
   - /characters
   - /characters/{key}/traits
   - /characters/{key}/traits/set
   - /characters/{key}/traits/history
   - /thought_templates/{parameter_key}
   - /thought_templates/{parameter_key}/upsert

Как применить (1 команда):
1) Распакуй архив в C:\AIGirl\patches\patch001\
2) Запусти PowerShell ОТ ИМЕНИ АДМИНИСТРАТОРА:
   cd C:\AIGirl\patches\patch001
   .\Apply-Patch1.ps1

Проверка:
- http://127.0.0.1:8001/health
- http://127.0.0.1:8001/characters
- http://127.0.0.1:8001/characters/nika/traits
