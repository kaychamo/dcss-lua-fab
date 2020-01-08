-- To use this create a macro with the following function call in game
-- ===animate

-- you can customize this level of hungriness
auto_butcher = full

explore_greedy = true
explore_stop = items,greedy_items,greedy_pickup
explore_stop += greedy_sacrificeable
explore_stop += greedy_visited_item_stack,stairs,shops,altars,gates

explore_auto_rest = true
auto_eat_chunks = true

: function animate()
:   local is_safe = (first_monster == nil)
:   local mp, max_mp = you.mp()
:   local hp, max_hp = you.hp()
:
:   local you_are_deep_dwarf = string.find(you.race(), "Deep Dwarf")
:   local you_are_mummy = string.find(you.race(), "Mummy")
:
:   local near_starving = ( string.find(you.hunger_name(), "near starving") )
:   local starving = ( string.find(you.hunger_name(), "starving") and not string.find(you.hunger_name(), "near") )
:   local should_rest = not_full(hp, mp, max_hp, max_mp)
:
:   local can_cast_regen = known_spells["Regeneration"] and (mp>3) and (spells.fail("Regeneration") < 20)
:   local you_know_sublimation = known_spells["Sublimation of Blood"] and (spells.fail("Sublimation of Blood") < 20) and (mp>3)
:   local you_know_animate_skeleton = known_spells["Animate Skeleton"] and (spells.fail("Animate Skeleton") < 20) and (mp>1)
:   local you_know_animate_dead = known_spells["Animate Dead"] and (spells.fail("Animate Dead") < 20) and (mp>4)
:
:
:   if should_rest then
:       crawl.mpr("<green>should rest.</green>")
:       if can_cast_regen then
:           crawl.mpr("<green>Autocasting Regen.</green>")
:           sendkeys('ze')
:       end
:       sendkeys('5')
:   end
:
:   if ( on_corpses() and (you_know_animate_skeleton or you_know_animate_dead) ) then
:       if (you_know_animate_dead) then
:         crawl.mpr("<cyan>Autocasting zb</cyan>")
:         sendkeys('zb')
:         if ( string.find(crawl.messages(3), escape("There is nothing here that can be animated")) ) then
:           sendkeys('o')
:         end

:       else if (you_know_animate_skeleton) then
:       crawl.mpr("<cyan>Autocasting zu</cyan>")
:       sendkeys('zu')
:       end
:
:       sendkeys('*e')
:       if (string.find(crawl.messages(10), escape("You travel at normal speed"))) then
:           sendkeys('*e')
:       end
:   end
:   sendkeys('o')
:
: end

<
  --function not_full(hp, mp, max_hp, max_mp)
  --  return ((hp < max_hp) or (mp < max_mp))
  --end

  function not_full(hp, mp, max_hp, max_mp)
    local you_are_mummy = string.find(you.race(), "Mummy")
    local you_are_deep_dwarf = string.find(you.race(), "Deep Dwarf")
    return  ( you.slowed()
            or you.poisoned()
            or you.confused()
            or you.exhausted()
            or ((hp < max_hp) or (mp < max_mp)) )
  end

  function on_corpses()
    local fl = you.floor_items()
    for it in iter.invent_iterator:new(fl) do
      if (string.find(it.name(), "corpse") or string.find(it.name(), "skeleton")) then
          --and not string.find(it.name(), "rotting")
          --and not string.find(it.name(), "plague") then
        return true
      end
    end
    return false
  end

  function floor_items()
    return iter.invent_iterator:new(you.floor_items())
  end

  function sendkeys(command)
    crawl.flush_input()
    crawl.sendkeys(command)
--    coroutine.yield(true)
    crawl.flush_input()
  end

  --Escapes the special characters in a string for pattern matching
  function escape(str)
    --Escapes parens and dash "()-"
    local escaped = str:gsub('[%(%)%-]','%\%1')
    --Removes any coloration parts of the string
    return (escaped:gsub('<[^<]*>',''))
  end

  local function init_spells()
    local spell_list = {}

    for _, spell_name in ipairs(you.spells()) do
      spell_list[spell_name] = true
    end

    return spell_list
  end

  known_spells = init_spells()
>