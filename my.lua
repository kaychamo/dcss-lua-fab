# csdc
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
:           sendkeys('zr')
:       end
:       sendkeys('5')
:   end
:
:   if ( on_corpses() and (you_know_sublimation or you_know_animate_skeleton or you_know_animate_dead) ) then
:       crawl.mpr("<cyan>Autocasting zu</cyan>")
:       sendkeys('zu')
:       if ( string.find(crawl.messages(3), escape("There is nothing here that can be animated")) ) then
:         sendkeys('o')
:       end
:
:       sendkeys('*e')
:       if ( string.find(crawl.messages(3), escape("You travel at normal speed")) ) then
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


#########################
# Good Beginner Options #
#########################

default_manual_training = true
autofight_stop = 80

show_more = false

#################
# Lua Functions #
#################

-----------------------------------------------------------------------------------
-- Armour/Weapon autopickup by rwbarton, enhanced by HDA with fixes from Bloaxor --
-----------------------------------------------------------------------------------
{

add_autopickup_func(function(it, name)

  if name:find("throwing net") then return true end
  
  local class = it.class(true)
  local armour_slots = {cloak="Cloak", helmet="Helmet", gloves="Gloves", boots="Boots", body="Armour", shield="Shield"}

  if (class == "armour") then
		if it.is_useless then return false end
		
    sub_type = it.subtype()
    equipped_item = items.equipped_at(armour_slots[sub_type])
 
    if (sub_type == "cloak") or (sub_type == "helmet") or (sub_type == "gloves") or (sub_type == "boots") then
      if not equipped_item then
        return true
      else
        return it.artefact or it.branded or it.ego
      end
    end
 
    if (sub_type == "body") then
      if equipped_item then
        local armourname = equipped_item.name()
        if equipped_item.artefact or equipped_item.branded or equipped_item.ego or (equipped_item.plus > 2) or armourname:find("dragon") or armourname:find("troll") then
          return it.artefact
        else
          return it.artefact or it.branded or it.ego
        end
      end
      return true
    end
 
    if (sub_type == "shield") then
      if equipped_item then
          return it.artefact or it.branded or it.ego
      end
    end
  end
end)

}

-------------------------
-- Dynamic Force Mores --
-------------------------
{

last_turn = you.turns()

fm_patterns = {
  {name = "XL5", cond = "xl", cutoff = 5, pattern = "adder|gnoll"},
  -- {name = "XL8", cond = "xl", cutoff = 8, pattern = "ogre|centaur|orc wizard|scorpion|worker ant"},
  -- {name = "XL15", cond = "xl", cutoff = 15, pattern = "two-headed ogre|centaur warrior|orc (warlord|knight)"},
  -- {name = "50mhp", cond = "maxhp", cutoff = 50, pattern = "orc priest|electric eel"},
  -- {name = "60mhp", cond = "maxhp", cutoff = 60, pattern = "acid dragon|steam dragon|manticore"},
  -- {name = "70mhp", cond = "maxhp", cutoff = 70, pattern = "meliai"}
} -- end fm_patterns

active_fm = {}
-- Set to true to get a message when the fm change
notify_fm = false

function init_force_mores()
  for i,v in ipairs(fm_patterns) do
    active_fm[#active_fm + 1] = false
  end
end

function update_force_mores()
  local activated = {}
  local deactivated = {}
  local hp, maxhp = you.hp()
  for i,v in ipairs(fm_patterns) do
    local msg = "(" .. v.pattern .. ").*into view"
    local action = nil
    local fm_name = v.pattern
    if v.name then
      fm_name = v.name
    end
    if not v.cond and not active_fm[i] then
      action = "+"
    elseif v.cond == "xl" then
      if active_fm[i] and you.xl() >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and you.xl() < v.cutoff then
        action = "+"
      end
    elseif v.cond == "rf" then
      if active_fm[i] and you.res_fire() >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and you.res_fire() < v.cutoff then
        action = "+"
      end
    elseif v.cond == "rc" then
      if active_fm[i] and you.res_cold() >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and you.res_cold() < v.cutoff then
        action = "+"
      end
    elseif v.cond == "relec" then
      if active_fm[i] and you.res_shock() >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and you.res_shock() < v.cutoff then
        action = "+"
      end
    elseif v.cond == "rpois" then
      if active_fm[i] and you.res_poison() >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and you.res_poison() < v.cutoff then
        action = "+"
      end
    elseif v.cond == "rcorr" then
      if active_fm[i] and you.res_corr() then
        action = "-"
      elseif not active_fm[i] and not you.res_corr() then
        action = "+"
      end
    elseif v.cond == "rn" then
      if active_fm[i] and you.res_draining() >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and you.res_draining() < v.cutoff then
        action = "+"
      end
    elseif v.cond == "fly" then
      if active_fm[i] and not you.flying() then
        action = "-"
      elseif not active_fm[i] and you.flying() then
        action = "+"
      end
    elseif v.cond == "mhp" then
      if active_fm[i] and maxhp >= v.cutoff then
        action = "-"
      elseif not active_fm[i] and maxhp < v.cutoff then
        action = "+"
      end
    end
    if action == "+" then
      activated[#activated + 1] = fm_name
    elseif action == "-" then
      deactivated[#deactivated + 1] = fm_name
    end
    if action ~= nil then
      local opt = "force_more_message " .. action .. "= " .. msg
      crawl.setopt(opt)
      active_fm[i] = not active_fm[i]
    end
  end
  if #activated > 0 and notify_fm then
    mpr("Activating force_mores: " .. table.concat(activated, ", "))
  end
  if #deactivated > 0 and notify_fm then
    mpr("Deactivating force_mores: " .. table.concat(deactivated, ", "))
  end
end

local last_turn = nil
function force_mores()
  if last_turn ~= you.turns() then
    update_force_mores()
    last_turn = you.turns()
  end
end

init_force_mores()

}

##################
# Ready Function #
##################

{

local need_skills_opened = true

function ready()

  force_mores()

-- Skill menu at game start by rwbarton
  if you.turns() == 0 and need_skills_opened then
    need_skills_opened = false
    crawl.sendkeys("m")
  end

end

}

#############
# Interface #
#############

autofight_throw = false
autofight_throw_nomove = false

show_travel_trail = true
travel_delay = -1
rest_delay = -1
auto_sacrifice = true

show_game_time = true

warn_hatches = false
jewellery_prompt = false
equip_unequip = true
allow_self_target = never
confirm_butcher = never
easy_eat_gourmand = true
sort_menus = true : equipped, identified, basename, qualname, charged
hp_warning = 50

auto_hide_spells = true
wall_jump_move = false

##############
# Autopickup #
##############

ae := autopickup_exceptions

# fab
ae += <box, <lamp
ae += <artefact
ae += <darts

ae ^= <scroll.*immolation.
ae ^= <scroll.*vulnerability.
ae += >scroll of amnesia
ae += >scroll of holy word
ae ^= <potion.*lignification.

ae += <wand of random effects
# ae += >wand of paralysis
# ae += >wand of lightning
# ae += >wand of confusion
# ae += >wand of digging
# ae += >wand of disintegration
# ae += >wand of polymorph
# ae += >wand of flame
# ae += >wand of enslavement

ae += <phantom mirror

ae += >ring of stealth
ae += >ring of positive energy
ae += >ring of fire
ae += >ring of ice
ae += >ring of magical power
ae += >ring of strength
ae += >ring of intelligence
ae += >ring of dexterity
ae += >ring of wizardry

ae += <gold
ae += <stone

#########
# Notes #
#########

dump_item_origins = all
dump_message_count = 50
dump_book_spells = false

##########
# Travel #
##########

explore_stop = items,greedy_items,greedy_pickup
#,greedy_pickup_gold
explore_stop += greedy_visited_item_stack,stairs,shops,altars,gates
explore_stop += greedy_sacrificeable
auto_exclude += oklob,statue,roxanne,hyperactive

stop := runrest_stop_message
ignore := runrest_ignore_message

# Annoyances
: if you.god() == "Jiyva" then
ignore += Jiyva gurgles merrily
ignore += Jiyva appreciates your sacrifice
ignore += Jiyva says: Divide and consume
ignore += You hear.*splatter
: end

ignore ^= You feel.*sick
ignore += disappears in a puff of smoke
ignore += engulfed in a cloud of smoke
ignore += standing in the rain
ignore += engulfed in white fluffiness
ignore += safely over a trap
ignore += A.*toadstool withers and dies
ignore += toadstools? grow
ignore += You walk carefully through the
ignore += chunks of flesh in your inventory.*rotted away
runrest_ignore_poison  = 5:10
runrest_ignore_monster += ^butterfly:1

# Bad things
stop += You fall through a shaft
stop += An alarm trap emits a blaring wail
stop += (blundered into a|invokes the power of) Zot
stop += A huge blade swings out and slices into you!
stop += flesh start
stop += (starving|feel devoid of blood)
stop += wrath finds you
stop += lose consciousness
stop += watched by something
stop += appears from out of your range of vision

# Expiring effects
stop += You feel yourself slow down
stop += less insulated
stop += You are starting to lose your buoyancy
stop += You lose control over your flight
stop += Your hearing returns
stop += Your transformation is almost over
stop += back to life
stop += uncertain
stop += time is quickly running out
stop += life is in your own hands
stop += is no longer charmed
stop += You start to feel a little slower
stop += You are no longer

: if you.race() == "Ghoul" then
stop += smell.*(rott(ing|en)|decay)
stop += something tasty in your inventory
: end

: if you.god() == "Xom" then
stop += god:
:else
ignore += god:
:end

ignore += pray:
ignore += talk:
ignore += talk_visual:
ignore += friend_spell:
ignore += friend_enchant:
ignore += friend_action:
ignore += sound:

###########
# prompts #
###########

flash_screen_message += You feel strangely unstable
flash_screen_message += Strange energies course through your body

more := force_more_message 

# distortion
more += Space warps horribly around you
more += hits you.*distortion
more += Space bends around you\.
more += Your surroundings suddenly seem different.
more += Its appearance distorts for a moment.

# ghost moths/antimagic
more += watched by something
more += You feel your power leaking

# torment/holy wrath
more += You convulse

# dispel breath
more += dispelling energy hits you

# early unseen horrors
more += It hits you!
more += Something hits you
more += Something. *misses you.

# more += You have reached level
more += You fall through a shaft
more += Training target.*for.*reached!
more += You now have enough gold to buy

# abyss convenience prompts
more += Found an abyssal rune
more += Found a gateway leading out of the Abyss
more += Found a gateway leading deeper into the Abyss

# necromutation
more += Your transformation is almost over.
more += You feel yourself coming back to life

# summon greater demon
more += is no longer charmed

# Announcements of timed portal vaults:
more += interdimensional caravan
more += distant snort
more += roar of battle
more += wave of frost
more += hiss of flowing sand
more += sound of rushing water
more += oppressive heat about you
more += crackle of arcane power
more += Found a gateway leading out of the Abyss
more += Found .* abyssal rune of Zot
more += You feel a terrible weight on your shoulders
more += .* resides here

# Interrupts
more += You don't.* that spell
more += You miscast (Controlled Blink|Blink|Death's|Borg|Necromutation)
more += You can't (read|drink|do) that
more += That item cannot be evoked
more += This wand has no charges
more += You are held in a net
more += You have disarmed
more += You don't have any such object
more += do not work when you're silenced
more += You can't unwield
more += enough magic points
more += You feel your control is inadequate
more += Something interferes with your magic
more += You enter a teleport trap

# Bad things
more += Your surroundings flicker
more += You cannot teleport right now
more += The writing blurs in front of your eyes
more += You fall through a shaft
more += A huge blade swings out and slices into you!
more += (blundered into a|invokes the power of) Zot
more += Ouch! That really hurt!
more += dispelling energy hits you
more += You convulse
more += You are (blasted|electrocuted)
more += You are.*confused
more += flesh start
more += (starving|devoid of blood)
more += god:(sends|finds|silent|anger)
more += You feel a surge of divine spite
more += lose consciousness
more += You are too injured to fight blindly
more += calcifying dust hits
more += Space warps horribly around you
more += hits you.*distortion
more += Space bends around you\.
more += watched by something
more += A sentinel's mark forms upon you
more += Your limbs have turned to stone
more += You are slowing down
more += .*LOW HITPOINT WARNING.*
more += warns you.*of distortion
more += lethally poison
more += space bends around your
more += wielding.*of (distortion|chaos)

# Gods
more += you are ready to make a new sacrifice
more += mollified
more += wrath finds you
more += sends forces
more += sends monsters
more += Vehumet offers

# Hell effects
# Re-enabled
more += "You will not leave this place."
more += "Die, mortal!"
more += "We do not forgive those who trespass against us!"
more += "Trespassers are not welcome here!"
more += "You do not belong in this place!"
more += "Leave now, before it is too late!"
more += "We have you now!"
more += You smell brimstone.
more += Brimstone rains from above.
more += You feel lost and a long, long way from home...
more += You shiver with fear.
more += You feel a terrible foreboding...
more += Something frightening happens.   
more += You sense an ancient evil watching you...
more += You suddenly feel all small and vulnerable.
more += You sense a hostile presence.
more += A gut-wrenching scream fills the air!
more += You hear words spoken in a strange and terrible language...
more += You hear diabolical laughter!

# Expiring effects
more += You feel yourself slow down
more += less insulated
more += You are starting to lose your buoyancy
more += You lose control over your flight
more += Your hearing returns
more += Your transformation is almost over
more += You have a feeling this form
more += You feel yourself come back to life
more += uncertain
more += time is quickly running out
more += life is in your own hands
more += is no longer charmed
more += shroud falls apart
more += You start to feel a little slower
more += You flicker
more += You feel less protected from missiles

# Skill breakpoints
more += skill increases

# Others
# more += You have reached level
more += You have finished your manual of
more += Your scales start
more += You feel monstrous
more += zaps a wand
more += carrying a wand
more += is unaffected
more += Jiyva alters your body

# Any uniques and any pan lords - doesn't seem to work
more += (?-i:[A-Z]).* comes? into view

more += Agnes.*comes? into view.
more += Aizul.*comes? into view.
more += Antaeus.*comes? into view.
more += Arachne.*comes? into view.
more += Asmodeus.*comes? into view.
more += Asterion.*comes? into view.
more += Azrael.*comes? into view.
more += Blork the orc.*comes? into view.
more += Boris.*comes? into view.
more += Cerebov.*comes? into view.
more += Crazy Yiuf.*comes? into view.
more += Dispater.*comes? into view.
more += Dissolution.*comes? into view.
more += Donald.*comes? into view.
more += Dowan.*comes? into view.
more += Duvessa.*comes? into view.
more += Edmund.*comes? into view.
more += Enchantress.*comes? into view.
more += Ereshkigal.*comes? into view.
more += Erica.*comes? into view.
more += Erolcha.*comes? into view.
more += Eustachio.*comes? into view.
more += Fannar.*comes? into view.
more += Frances.*comes? into view.
more += Francis.*comes? into view.
more += Frederick.*comes? into view.
more += Gastronok.*comes? into view.
more += Geryon.*comes? into view.
more += Gloorx Vloq.*comes? into view.
more += Grinder.*comes? into view.
more += Grum.*comes? into view.
more += Harold.*comes? into view.
more += Ignacio.*comes? into view.
more += Ijyb.*comes? into view.
more += Ilsuiw.*comes? into view.
more += Jorgrun.*comes? into view.
more += Jory.*comes? into view.
more += Jessica.*comes? into view.
more += Joseph.*comes? into view.
more += Josephine.*comes? into view.
more += Jozef.*comes? into view.
more += Khufu.*comes? into view.
more += Kirke.*comes? into view.
more += Lamia.*comes? into view.
more += Lom Lobon.*comes? into view.
more += Louise.*comes? into view.
more += Mara.*comes? into view.
more += Margery.*comes? into view.
more += Maud.*comes? into view.
more += Maurice.*comes? into view.
more += Menkaure.*comes? into view.
more += Mennas.*comes? into view.
more += Mnoleg.*comes? into view.
more += Murray.*comes? into view.
more += Natasha.*comes? into view.
more += Nergalle.*comes? into view.
more += Nessos.*comes? into view.
more += Nikola.*comes? into view.
more += Norris.*comes? into view.
more += Pikel.*comes? into view.
more += Polyphemus.*comes? into view.
more += Prince Ribbit.*comes? into view.
more += Psyche.*comes? into view.
more += Purgy.*comes? into view.
more += Robin.*comes? into view.
more += Roxanne.*comes? into view.
more += Rupert.*comes? into view.
more += Saint Roka.*comes? into view.
more += Sigmund.*comes? into view.
more += Snorg.*comes? into view.
more += Sojobo.*comes? into view.
more += Sonja.*comes? into view.
more += Terence.*comes? into view.
more += The Lernaean hydra.*comes? into view.
more += The royal jelly.*comes? into view.
more += The Serpent of Hell.*comes? into view.
more += Tiamat.*comes? into view.
more += Urug.*comes? into view.
more += Vashnia.*comes? into view.
more += Wiglaf.*comes? into view.
more += Xtahua.*comes? into view.

more += 27-headed.*comes? into view.
more += .*player ghost.* comes? into view
more += .*Ancient Lich.*comes? into view.
more += .*Orbs? of Fire.*comes? into view.
more += .*Fiend.*comes? into view.
more += .*Hellion.*comes? into view.
more += .*Tormentor.*comes? into view.
more += .*Hell Sentinel.*comes? into view.
more += .*Executioner.*comes? into view.
more += .*Neqoxec.*comes? into view.
more += .*Cacodemon.*comes? into view.
more += .*Shining Eye.*comes? into view.
more += .*Greater Mummy.*comes? into view.
more += .*Mummy Priest.*comes? into view.
more += .*Curse Toe.*comes? into view.
more += .*Curse Skull.*comes? into view.
more += .*('s|s') ghost.*comes? into view.
more += .*shrike.*comes? into view.
more += .*wretched star.*comes? into view
more += .*lurking horror.*comes? into view
more += .*Juggernaut.*comes? into view.
more += .*Iron Giant.*comes? into view.
more += .*Tzitzimimeh.*comes? into view.
more += .*Tzitzimitl.*comes? into view.

# Paralysis enemies
more += .*Floating Eye.*comes? into view.
more += .*Lich.*comes? into view.
more += .*Ogre Mage.*comes? into view.
more += .*a Wizard.*comes? into view.
more += .*orc sorcerer.*comes? into view.
more += .*sphinx.*comes? into view.
more += .*Great orb of eyes.*comes? into view.
more += .*Vampire knight.*comes? into view.

# Other dangerous enemies
more += minotaur.*into view
more += *guardian serpent.*comes? into view.
more += .*vault sentinel.*comes? into view.
more += .*vault warden.*comes? into view.
more += .*ironbrand convoker.*comes? into view.

# Dancing weapon
more += Your.*falls from the air.

# Xom is scary
: if you.god() == "Xom" then
more += god:
: end

####################
# Autoinscriptions #
####################

ai := autoinscribe

ai += (bad|dangerous)_item.*potion:!q
ai += (bad|dangerous)_item.*scroll:!r
ai += of faith:!P
ai += rod of:!a
ai += lightning rod:!a
ai += [^r]staff of (conj|energy|power|wizardry):!a
ai += manual of:!d
ai += dispersal:!f
ai += tome of Destruction:!d
ai += throwing net:!f
ai += curare:!f
ai += needle of (frenzy|paralysis|sleeping|confusion):!f
ai += ( ration):!d
ai += figurine:!*

: if you.god() ~= "Lugonu" then
ai += (distortion):!w
:end

ai += of identify:@r1
ai += remove curse:@r2
ai += curing:@q1
ai += potions? of heal wounds:@q2
ai += wand of heal wounds:@v2
ai += wand of hasting:@v3
ai += potions? of haste:@q3
ai += scrolls? of teleportation:@r4
ai += wand of teleportation:@v4
ai += potions? of blood:@q0

####################
# Mute some messages #
####################

msc := message_colour

# Muted - unnecessary
msc += mute:The (bush|fungus|plant) is engulfed
msc += mute:The (bush|fungus|plant) is struck by lightning
msc += mute:Cast which spell
msc += mute:Use which ability
msc += mute:Evoke which item
msc += mute:Confirm with
# msc += mute:(Casting|Aiming|Aim|Zapping)\:
msc += mute:Throwing.*\:
msc += mute:You can\'t see any susceptible monsters within range
msc += mute:Press\: \? \- help, Shift\-Dir \- straight line, f \- you
msc += mute:for a list of commands and other information
msc += mute:Firing \(i
msc += mute:Fire\/throw which item\?
msc += mute:You swap places

msc ^= mute:is lightly (damaged|wounded)
msc ^= mute:is moderately (damaged|wounded)
msc ^= mute:is heavily (damaged|wounded)
msc ^= mute:is severely (damaged|wounded)
msc ^= mute:is almost (dead|destroyed)

msc += mute:Was it this warm in here before
msc += mute:The flames dance
msc += mute:Your shadow attacks
msc += mute:Marking area around
msc += mute:Placed new exclusion
msc += mute:Reduced exclusion size to a single square
msc += mute:Removed exclusion
msc += mute:You can access your shopping list by pressing
msc += mute:for starvation awaits
msc += mute:As you enter the labyrinth
msc += mute:previously moving walls settle noisily into place
msc += mute:You offer a prayer to Elyvilon
msc += mute:You offer a prayer to Nemelex Xobeh
msc += mute:You offer a prayer to Okawaru
msc += mute:You offer a prayer to Makhleb
msc += mute:You offer a prayer to Lugonu
msc += mute:Lugonu accepts your kill
msc += mute:Okawaru is noncommittal
msc += mute:Nemelex Xobeh is (noncommittal|pleased)
msc += mute:The plant looks sick
msc += mute:You start butchering
msc += mute:You continue butchering
msc += mute:This raw flesh tastes terrible

: if string.find(you.god(), "Jiyva") then
  msc += mute:You hear a.*slurping noise
  msc += mute:You hear a.*squelching noise
  msc += mute:You feel a little less hungry
: end

###############
# Spell slots #
###############

spell_slot += Animate Skeleton:u
spell_slot += Animate Dead:u
spell_slot += Apportation:c
spell_slot += Beastly Appendage:a
spell_slot += Blink:b
spell_slot += Bolt of Cold:c
spell_slot += Bolt of Fire:c
spell_slot += Borgnjor's Vile Clutch:f
spell_slot += Call Canine Familiar:c
spell_slot += Call Imp:x
spell_slot += Cause Fear:f
spell_slot += Confuse:c
spell_slot += Confusing Touch:a
spell_slot += Conjure Flame:d
spell_slot += Corona:a
spell_slot += Corpse Rot:d
spell_slot += Dazzling Spray:s
spell_slot += Deflect Missiles:r
spell_slot += Dispel Undead:d
spell_slot += Ensorcelled Hibernation:x
spell_slot += Fireball:x
spell_slot += Flame Tongue:a
spell_slot += Freeze:a
spell_slot += Freezing Cloud:d
spell_slot += Fulminant Prism:z
# spell_slot += Haste:s
spell_slot += Ice Form:c
spell_slot += Infusion:a
spell_slot += Iskenderun's Battlesphere:i
spell_slot += Iskenderun's Mystic Blast:x
spell_slot += Magic Dart:a
spell_slot += Mephitic Cloud:f
spell_slot += Olgreb's Toxic Radiance:y
spell_slot += Orb of Destruction:zZ
spell_slot += Pain:a
spell_slot += Passage of Golubria:v
spell_slot += Passwall:qQ
# spell_slot += Phase Shift:aA
spell_slot += Poisonous Vapours:x
spell_slot += Portal Projectile:d
spell_slot += Regeneration:e
# spell_slot += Repel Missiles:r
spell_slot += Sandblast:a
spell_slot += Searing Ray:s
spell_slot += Shock:a
spell_slot += Shroud of Golubria:q
spell_slot += Silence:g
spell_slot += Slow:s
spell_slot += Song of Slaying:w
spell_slot += Spectral Weapon:t
spell_slot += Spider Form:x
spell_slot += Static Discharge:d
spell_slot += Sticks to Snakes:s
spell_slot += Sticky Flame:q
spell_slot += Sting:a
spell_slot += Stone Arrow:x
spell_slot += Sublimation of Blood:Z
spell_slot += Summon Butterflies:n
spell_slot += Summon Ice Beast:d
spell_slot += Summon Lightning Spire:z
spell_slot += Summon Mana Viper:w
spell_slot += Summon Small Mammal:a
spell_slot += Swiftness:s
spell_slot += Throw Flame:x
spell_slot += Throw Frost:x
spell_slot += Throw Icicle:c
spell_slot += Tukima's Dance:d
spell_slot += Vampiric Draining:q


###############
# Item slots #
###############

# item_slot += wand of teleportation:g
# item_slot += wand of hasting:s
# item_slot += wand of heal wounds:e
item_slot += wand of digging:v
item_slot += wand of disintegration:c
# item_slot += wand of confusion:y
item_slot += wand of paralysis:u
item_slot += wand of iceblast:d
item_slot += wand of acid:x
# item_slot += wand of lightning:f
item_slot += wand of flame:t

item_slot += ring of see invisible:z
item_slot += ring of protection from magic:l
item_slot += ring of protection from fire:i
item_slot += ring of protection from cold:o

item_slot += ration:e
item_slot += potion of blood:q
item_slot += poison needle: Q

#################
# Ability slots #
#################
ability_slot += corrupt:Y

##############################################################################################
##############################################################################################
##############################################################################################
# NOTE: IF YOU DON'T WANT TO MESS AROUND WITH COLOURS YOU CAN DELETE EVERYTHING FROM HERE ON #
##############################################################################################
##############################################################################################
##############################################################################################

####################
# HDA Colour Stuff #
####################

#########################
# Aliases and Variables #
#########################

# Set Alias
menu := menu_colour
# Clear defaults
menu =

# Variables (Worst to Best)
$evil := red
$negative := brown
$danger := lightred
$warning := yellow
$boring := darkgrey
$decent := white
$good := lightblue
$positive := green
$verypositive := lightgreen
$awesome := lightmagenta

# Unusual Variables
$mp := lightcyan
$equipped := cyan
$mutation := magenta

##################
# Basic Settings #
##################

# General Categories
menu += $boring:(melded)
menu += $boring:.*useless_item.*
menu += $evil:.*evil_item.*
menu += $danger:[^n]cursed
menu += inventory:$danger:[^n]cursed
menu += inventory:$equipped:.*equipped.*
menu += $decent:.*artefact.*

# Unidentified Items
menu += $warning:^unidentified .*(jewellery|potion|scroll|wand).*
menu += $good:^unidentified .*armour.*(embroidered|dyed|glowing|shiny|runed)
menu += $good:^unidentified .*weapon.*(glowing|runed)

#################
# Various Items #
#################

# Amulets
menu += $boring:amulet of inaccuracy
menu += $good:amulet of (guardian spirit|stasis|warding)
menu += $positive:amulet of (faith|rage|resist corrosion)
menu += $verypositive:amulet of (clarity|regeneration|resist mutation|the gourmand)

# Decks (keep warning as default in case of new decks)
menu += $evil:deck of punishments
menu += $warning:deck of (changes|destruction)
menu += $decent:deck of cards
menu += $good:deck of war
menu += $positive:deck of (defence|summoning)
menu += $verypositive:deck of escape
menu += $awesome:deck of wonders
menu += $warning:deck of 

# Evokables
menu += blue:inert
menu += $warning:disc of storms
menu += $warning:tome of Destruction
menu += $decent:box of beasts
menu += $decent:lantern of shadows
menu += $decent:stone of tremors
menu += $good:fans? of gales
menu += $good:lamps? of fire
menu += $good:phials? of floods
menu += $good:sack of spiders
menu += $positive:phantom mirror
menu += $mp:crystal ball of energy

# Food
menu += $evil:evil_eating
menu += $danger:rot-inducing
menu += $warning:poisonous
menu += $boring:inedible
menu += $good:bread ration
menu += $good:meat ration
menu += $good:preferred
menu += $good:(corpse|chunk)
menu += $mutation:mutagenic

# Potions
menu += $danger:potions? of berserk
menu += $decent:potions? of (flight|lignification|restore)
menu += $good:potions? of (agility|brilliance|invisibility|might|resistance)
menu += $positive:potions? of curing
menu += $verypositive:potions? of (haste|heal wounds)
menu += $awesome:potions? of (beneficial|cancellation|cure mutation|experience|gain)
menu += $mp:potions? of magic
menu += $mutation:potions? of mutation

# Rings
menu += $negative:ring of \-.*(dexterity|evasion|intelligence|protection|slaying|strength)
menu += $negative:ring of loudness
menu += $warning:ring of (fire|ice)
menu += $decent:ring of flight
menu += $good:ring of (.*evasion|invisibility|magical power|.*protection|stealth|sustain abilities|wizardry)
menu += $positive:ring of (poison resistance|protection from cold|protection from fire|protection from magic|see invisible)
menu += $verypositive:ring of (regeneration|.*slaying)
menu += $awesome:ring of teleport

# Rods
menu += $verypositive:rod

# Scrolls
menu += $danger:scrolls? of torment
menu += $boring:scrolls? of (noise|random)
menu += $decent:scrolls? of (amnesia|holy word|identify|remove curse)
menu += $good:scrolls? of (fear|fog|immolation|silence|summoning|vulnerability)
menu += $positive:scrolls? of (brand|enchant|magic mapping|recharging)
menu += $verypositive:scrolls? of acquirement
menu += $awesome:scrolls? of (blinking|teleportation)

# Staves
menu += $mp:staff of (energy|Wucad Mu)
menu += $positive:[^r]staff of

# Wands
menu += $boring:wand of (flame|frost|magic darts|random effects)
menu += $decent:wand of (confusion|enslavement|paralysis|polymorph|slowing)
menu += $good:wand of (cold|digging|disintegration|draining)
menu += $good:wand of (fire|fireball|invisibility|lightning)
menu += $positive:wand of hasting
menu += $verypositive:wand of heal wounds
menu += $awesome:wand of teleportation

# Other
menu += $negative:shield of the gong
menu += $good:throwing net
menu += $awesome:.*misc.*rune( of Zot)?
menu += $awesome:.*orb.*Zot
menu += $awesome:manual

####################
# Message coloring #
####################

# Standard Colors
# black, blue, brown, cyan, darkgrey, green, lightblue, lightcyan, lightgreen,
# lightgrey, lightmagenta, lightred, magenta, red, yellow, white

# Variables for message highlighting
$danger   := lightred
$item_dmg := red
$warning  := yellow
$boring   := darkgrey
$negative := brown
$good     := lightblue
$positive := green
$verypositive := lightgreen
$awesome := lightmagenta
$interface := cyan
$takesaction := blue
$godaction := magenta
$mp := lightcyan

#Channels
#channel.plain = 
channel.prompt = $interface
channel.god = $godaction
channel.pray = $godaction
channel.duration = $warning
channel.danger = $danger
channel.food = $warning
channel.warning = $danger
channel.recovery = $verypositive
channel.talk = $warning
channel.talk_visual = $boring
channel.timed_portal = $warning
#channel.sound = 
channel.intrinsic_gain = $awesome
#channel.mutation = --either danger/warning/awesome
channel.monster_spell = $takesaction
#channel.monster_enchant = --either danger/warning/boring/takesaction
channel.friend_spell = $takesaction
#channel.friend_enchant = --either danger/warning/boring/takesaction
channel.friend_action = $takesaction
channel.monster_damage = mute
#monster_target = --currently unused by the game
#channel.banishment = --either positive or danger
channel.rotten_meat = $boring
channel.equipment = $interface
#channel.floor = 
channel.multiturn = $boring
#channel.examine = 
#channel.examine_filter = 
#channel.diagnostics = 
#channel.error = 
#channel.tutorial = 
channel.orb = $awesome
#channel.hell_effect = -either danger/warning/boring

# Set Alias
msc := message_colour
# Clear defaults
msc = 

msc += $mp:You feel your power returning

#msc += $danger:
msc += $danger:The entropy weaver begins to chant a word of entropy
msc += $danger:Your corrosive artefact corrodes you
msc += $danger:cannot move out of your way
msc += $danger:Tentacles burst from Mnoleg
msc += $danger:tentacle flies out from Mnoleg
msc += $danger:roused to righteous anger
msc += $danger:is roused by the hymn
msc += $danger:A magical barricade bars your way
msc += $danger:is repulsed
msc += $danger:seems less drained
msc += $danger:preventing you from leaping
msc += $danger:shrugs off the wave
msc += $danger:Your unholy channel expires
msc += $danger:Being near the torpor snail leaves you feeling lethargic
msc += $danger:The amulet engulfs you in a massive magical discharge
msc ^= $danger:Your.*appears confused
msc ^= $danger:You open a gate to Pandemonium
msc += $danger:Some icy apparitions appear
msc += $danger:You feel less empathic
msc ^= $danger:Qazlal is no longer ready to protect you from an element
msc ^= $danger:Your divine halo fades away
msc ^= $danger:Your divine shield disappears
msc ^= $danger:The orb of electricity explodes
msc ^= $danger:Your divine shield fades away
msc += $danger:visions of slaying
msc += $danger:You.*no longer.*bleed smoke
msc += $danger:Your shadow no longer tangibly mimics your actions
msc += $danger:You are even more entangled
msc += $danger:You have drawn Pain
msc += $danger:Your magical shield disappears
msc ^= $danger:Your.*drowns
msc += $danger:creates some ice likenesses
msc += $danger:soul is no longer ripe for the taking
msc += $danger:You are no longer magically infusing your attacks
msc += $danger:The ambient light returns to normal
msc += $danger:An iron grate slams shut
msc += $danger:begins to accept
msc += $danger:begins to recite a word of recall
msc += $danger:begins to radiate toxic energy
msc += $danger:The shadow imp is revulsed by your support of nature
msc += $danger:Careful! You are starting to lose your buoyancy
msc ^= $danger:plants?.*suddenly grows? acid sacs
msc ^= $danger:Your.*is devoured by a tear in reality
msc += $danger:Your body is bloodless
msc += $danger:Your unliving flesh cannot be transformed in this way
msc += $danger:You feel less resistant to cold
msc += $danger:You can't disarm
msc += $danger:You feel strangely static
msc += $danger:A powerful magic interferes with your control of the blink
msc += $danger:burns you terribly
msc += $danger:You are no longer teleporting projectiles to their destination
msc += $danger:Water floods your area
msc += $danger:You feel the presence of a powerless spirit
msc += $danger:You feel less resistant to (cold|fire)
msc += $danger:You feel less protected from
msc += $danger:You hear a crashing sound
msc += $danger:The tree smolders and burns
msc ^= $danger:You are contaminated with residual magics
msc += $danger:is duplicated
msc += $danger:You sense a malign presence
msc += $danger:The deck only has
msc += $danger:blocks your orb of destruction
msc += $danger:There are no remains here to animate
msc += $danger:Your ring of flames gutters out
msc += $danger:The elephant guardians awaken
msc += $danger:slides away
msc += $danger:moves from beneath you
msc += $danger:A powerful magic prevents control of your teleportation
msc += $danger:There's only.*cards? left!
msc += $danger:A huge vortex of air appears
msc += $danger:you're silenced
msc += $danger:Your hands slow down
msc += $danger:Your shroud falls apart
msc += $danger:Not with that terrain in the way
msc += $danger:Your teleport is interrupted
msc += $danger:Your.*revert to.*normal proportions
msc += $danger:Its appearance distorts for a moment
msc += $danger:A shaft opens up in the floor
msc += $danger:You are held in a net
msc += $danger:(The|Your).*falls away!
msc += $danger:The orbs collide in a blinding explosion
msc += $danger:You feel the power of the Abyss delaying your translocation
msc += $danger:Mara shimmers
msc += $danger:Your.*is blown up
msc += $danger:seems to grow more fierce
msc += $danger:attacks!
msc += $danger:You sense the presence of something unfriendly
msc += $danger:Your.*falls into the water
msc += $danger:Something unseen opens the huge gate
msc += $danger:changes into something you cannot see
msc += $danger:The rod doesn't have enough magic points
msc += $danger:The power of the Abyss keeps you in your place
msc += $danger:Your.*is destroyed
msc += $danger:You feel your control is inadequate
msc += $danger:A great vortex of raging winds appears
msc += $danger:You blow up your
msc += $danger:The sixfirhy seems to be charged up
msc += $danger:You feel your power drain away
msc += $danger:You cannot cast spells when silenced
msc += $danger:You feel hot and cold all over
msc += $danger:You don't have the energy to cast that spell
msc += $danger:and don't expect to remain undetected
msc += $danger:but the box appears empty
msc += $danger:your gold pieces vanish
msc += $danger:Your.*dies
msc += $danger:You cannot teleport right now
msc += $danger:You feel your power drawn to a protective spirit
msc += $danger:your magic stops regenerating
msc += $danger:Some monsters swap places
msc += $danger:You turn into a spiny porcupine
msc += $danger:Your limbs have turned to stone
msc += $danger:Your skin feels tender
msc += $danger:You turn into a fleshy mushroom
msc += $danger:The sound of falling rocks suddenly begins to subside
msc += $danger:The walls and floor vibrate strangely for a moment
msc += $danger:Your.*(armour|shield) melts away
msc += $danger:drains you
msc += $danger:You need to eat something NOW
msc += $danger:feel drained
msc += $danger:strangely unstable
msc += $danger:curare-tipped.*hits you
msc += $danger:Space warps.* around you
msc += $danger:Space bends around you
msc += $danger:Space bends sharply around you!
msc += $danger:sense of stasis
msc += $danger:clumsily bash
msc += $danger:goes berserk
msc += $danger:Forgetting.* will destroy the book
msc += $danger:The blast of calcifying dust hits you
msc += $danger:You are engulfed in calcifying dust
msc += $danger:^It .* you
msc += $danger:[^f]Something.*you[^r]
msc += $danger:grabs you[^r]
msc += $danger:you convulse
msc += $danger:is unaffected
msc += $danger:blinks into view
msc += $danger:seems to speed up
msc += $danger:You feel yourself slow down
msc += $danger:The alarm trap emits a blaring wail
msc += $danger:The mark upon you grows brighter.
msc += $danger:flickers (and vanishes|out of sight)
msc += $danger:Terrible wounds (open|spread)
msc += $danger:The acid burns
msc += $danger:The.*is recalled
msc += $danger:The.*blows on a signal horn!
msc += $danger:You miscast
msc += $danger:zaps a wand
msc += $danger:You are no longer berserk
msc += $danger:You suddenly lose the ability to move
msc += $danger:Your.*glows black for a moment
msc += $danger:You are caught in a web
msc += $danger:You are knocked back by the lance of force
msc += $danger:You are knocked back by the blast of cold
msc += $danger:You are knocked back by the great wave of water
msc += $danger:You feel very sick
msc += $danger:Your.*falls away
msc += $danger:splits in two
msc += $danger:assumes the form|sacrifices itself
msc += $danger:Necromantic energies
msc += $danger:You feel an extremely numb sensation
msc += $danger:You feel jittery for a moment
msc += $danger:You are caught in (a|the) (net|web)
msc += $danger:You become entangled in (a|the) (net|web)
msc += $danger:You fall asleep
msc += $danger:The forest starts to sway and rumble
msc += $danger:Vines fly forth from the trees!
msc += $danger:Roots grasp at your
msc += $danger:Roots rise up from beneath you and drag you back to the ground
msc += $danger:The.*picks up a wand
msc += $danger:You struggle against (a|the) (net|web)
msc += $danger:You struggle to escape the net
msc += $danger:The.*engulfs you in water
msc += $danger:Your magical defenses are stripped away
msc += $danger:appears out of thin air
msc += $danger:You feel less protected from missiles
msc += $danger:The power of Zot is invoked against
msc += $danger:you fail to dodge
msc += $danger:Death has come for you
msc += $danger:Your body is wracked with pain
msc += $danger:You sense an overwhelmingly malignant aura
msc += $danger:Space twists in upon itself
msc += $danger:Strange energies course through your body
msc += $danger:You feel haunted
msc += $danger:Your.*suddenly stops moving
msc += $danger:You feel incredibly sick
msc += $danger:You don't have enough magic
msc += $danger:You haven't enough magic at the moment
msc += $danger:You fall through a shaft
msc += $danger:seems to grow stronger
msc += $danger:Dowan seems to find hidden reserves of power
msc += $danger:Oops, that.*feels deathly cold
msc += $danger:You struggle to resist
msc += $danger:You barely resist
msc += $danger:You turn into an animated tree
msc += $danger:Your roots penetrate the ground
msc += $danger:is no longer charmed
msc += $danger:You try to slip out of the net
msc += $danger:You become entangled in the net
msc += $danger:You feel a build-up of mutagenic energy
msc += $danger:You cannot pacify this monster
msc += $danger:You feel a (horrible|terrible) chill
msc += $danger:You are burned terribly
msc += $danger:moth of wrath (goads|infuriates) the
msc += $danger:you trip and fall back down the stairs
msc += $danger:the glow from your corona prevents you from becoming completely invisible
msc += $danger:A red film seems to cover your vision as you go berserk
msc += $danger:Your limbs are stiffening
msc += $danger:You have turned to stone
msc += $danger:Draining that being is not a good idea
msc += $danger:You feel.*ill
msc += $danger:You can't gag anything down
msc += $danger:Something feeds on your intellect
msc += $danger:The barbed spikes become lodged in your body
msc += $danger:You feel your translocation being delayed
msc += $danger:You fail to use your ability
msc += $danger:Oh no! You have blundered into a Zot trap
msc += $danger:Wisps of shadow swirl around
msc += $danger:The.*grows two more
msc += $danger:There is a sealed passage
msc += $danger:doors? slams? shut
msc += $danger:A basket of spiders falls from above
msc += $danger:is bolstered by the flame
msc ^= $danger:Mennas' surroundings become eerily quiet
msc += $danger:attempts to bespell you
msc += $danger:You feel horribly lethargic
msc += $danger:firmly anchored in space
msc += $danger:You stop (a|de)scending the stairs
msc += $danger:You tear a large gash into the net
msc += $danger:reflects
msc += $danger:The walls disappear
msc += $danger:You cannot afford.*fee
msc += $danger:This weapon is already enchanted
msc += $danger:You feel.*sluggish
msc += $danger:You no longer adapt resistances upon receiving elemental damage
msc += $danger:The storm surrounding you is now too weak to repel missiles
msc += $danger:You feel extremely strange
msc += $danger:This meat tastes really weird
msc += $danger:You finish putting on your cursed
msc += $danger:It was a potion of paralysis
msc += $danger:You feel rather ponderous
msc += $danger:That seemed strangely inert
msc += $danger:You can't unwield your weapon to draw a new one
msc += $danger:the volcano erupts with a roar
msc += $danger:too hungry
msc += $danger:Your guardian golem overheats
msc += $danger:burn any scroll you tried to read
msc += $danger:You are blown backwards
msc += $danger:It is caustic
msc += $danger:Not only inedible but also greatly harmful
msc += $danger:evokes.*(amulet|ring)
msc += $danger:take too long for a potion to reach your roots
msc += $danger:There was something very wrong with that liquid
msc += $danger:You cannot move
msc += $danger:stands defiantly in death's doorway
msc += $danger:zaps a rod
msc += $danger:twongs alarmingly
msc += $danger:You feel yourself grow more vulnerable to poison
msc += $danger:The poison in your body grows stronger
msc += $danger:You are being crushed by all of your possessions
msc += $danger:You are carrying too much
msc += $danger:You draw Wild Magic
msc += $danger:You draw the Helix
msc += $danger:This potion can/'t work under stasis
msc += $danger:Your icy (armour|shield) evaporates
msc += $danger:You struggle to detach yourself from the web
msc += $danger:You are more confused
msc += $danger:You are confused
msc += $danger:breaks free
msc += $danger:(You are|You're) too confused
msc += $danger:Your skin stops crawling
msc += $danger:Your attempt to break free
msc += $danger:Your resistance to elements expires
msc += $danger:You are blasted by holy energy
msc += $danger:You feel uncertain
msc += $danger:You are firmly grounded in the material plane once more
msc += $danger:The writing blurs in front of your eyes
msc += $danger:You cannot cast spells while unable to breathe
msc += $danger:You feel your rage building
msc += $danger:You feel a little less
msc += $danger:You are wearing\:.*cursed
msc += $danger:This card doesn't seem to belong here
msc += $danger:You flicker back
msc += $danger:something.*blocking the
msc += $danger:You slice into (a|the) (net|web)
msc += $danger:It doesn't seem very happy
msc += $danger:You have been turned into a pig
msc += $danger:comes? into view
msc += $danger:You feel quite a bit less full
msc += $danger:Your unstable footing causes you to fumble your attack
msc += $danger:You are being weighed down by all of your possessions
msc += $danger:flinch away in fear
msc += $danger:is completely unfazed by your meager offer of peace
msc += $danger:deflects the
msc += $danger:The blink frog basks in the distortional energy
msc += $danger:appears unharmed
msc ^= $danger:You and your allies can no longer gain power from killing the unholy and evil
msc += $danger:You have lost your religion
msc += $danger:Your shroud unravels
msc += $danger:Your attacks are no longer magically infused
msc += $danger:You feel your attacks grow feeble
msc += $danger:Magical energy is drained from your
msc += $danger:A chorus of chattering voices calls out to you
msc += $danger:You can no longer
msc += $danger:The.*shudders
msc ^= $danger:Your unholy and evil allies forsake you
msc += $danger:Your transformation has ended
msc += $danger:Nothing appears to have answered your call
msc += $danger:The grasping roots prevent you from becoming airborne
msc += $danger:You kill your
msc += $danger:You feel less regenerative
msc += $danger:Lernaean hydra knocks down a tree
msc += $danger:You are caught in an explosion of electrical discharges
msc += $danger:bends your attack away
msc += $danger:Your song has ended
msc += $danger:goes into a battle-frenzy
msc += $danger:Your aura of abjuration expires
msc += $danger:Your.*is blown up
msc += $danger:There's only one card left
msc += $danger:You deal a card
msc += $danger:darts out from under the net
msc += $danger:You wield the.*\'s
msc += $danger:dips into the water
msc += $danger:You destroy your
msc += $danger:You're too exhausted to jump
msc += $danger:Your battlesphere expends the last of its energy and dissipates
msc += $danger:You feel your bond with your battlesphere wane
msc += $danger:Your battlesphere wavers and loses cohesion
msc += $danger:You lose concentration completely
msc += $danger:go into a battle-frenzy
msc += $danger:You can't jump while in water
msc += $danger:staircase.*moves
msc += $danger:You wield
msc += $danger:is filled with.*inner flame
msc += $danger:You feel guilty
msc += $danger:You feel extremely guilty
msc += $danger:picks up.*throwing net
msc += $danger:You feel less protected from physical attacks
msc ^= $danger:Your.*falters for a moment
msc += $danger:Mutagenic energy flows through the plutonium sword
msc += $danger:Your spectral weapon fades away
msc += $danger:Your.*is incinerated
msc ^= $danger:begins absorbing vital energies
msc += $danger:Blessed fire suddenly surrounds you
msc ^= $danger:Your.*is poisoned
msc ^= $danger:Your.*looks even sicker
msc ^= $danger:Your.*is no longer beserk
msc += $danger:You swing wildly
msc += $danger:You lose your focus
msc += $danger:You feel threatened and lose the ability
msc += $danger:is too large for the net to hold
msc ^= $danger:Your.*looks rather confused
msc += $danger:The moth of wrath goads something on
msc += $danger:The net passes right through
msc += $danger:A tornado forms
msc ^= $danger:burns? away your fire resistance

# Item Destruction, gaining bad mutations, or losing good ones, penance, and gong
msc += $item_dmg:You feel your body start to fall apart
msc += $item_dmg:Your teeth shrink to normal size
msc += $item_dmg:Your.*scales disappear
msc += $item_dmg:You feel a strong urge to (yell|scream|shout)
msc += $item_dmg:Your wild genetic ride slows down
msc += $item_dmg:The barb on your tail disappears
msc += $item_dmg:Your wings shrivel and weaken
msc += $item_dmg:You feel very strange
msc += $item_dmg:You feel conductive
msc += $item_dmg:A chill runs up and down your throat
msc += $item_dmg:You feel forlorn
msc += $item_dmg:Your skin no longer functions as natural camouflage
msc += $item_dmg:Your natural healing is weakened
msc += $item_dmg:Your rate of healing slows
msc += $item_dmg:Your talons dull and shrink into feet
msc += $item_dmg:You feel genetically unstable
msc += $item_dmg:The horns on your head shrink a bit
msc += $item_dmg:You feel an ache in your throat
msc += $item_dmg:You feel yourself wasting away
msc += $item_dmg:You feel angry
msc += $item_dmg:You feel a little pissed off
msc += $item_dmg:You feel extremely angry at everything
msc += $item_dmg:Your hooves look more like feet
msc += $item_dmg:Your hooves expand and flesh out into feet
msc += $item_dmg:You feel a little hungry
msc += $item_dmg:A piece of fruit is consumed
msc += $item_dmg:pieces of fruit are consumed
msc += $item_dmg:You feel slightly disoriented
msc += $item_dmg:Your system partially rejects artificial healing
msc += $item_dmg:You feel even more weirdly uncertain
msc += $item_dmg:You feel weirdly uncertain
msc += $item_dmg:The drain falls to bits
msc += $item_dmg:acid corrodes
msc += $item_dmg:The rust devil corrodes your equipment
msc += $item_dmg:catch(es)? fire
msc ^= $item_dmg:freezes? and shatters?
msc += $item_dmg:covered with spores
msc += $item_dmg:devours some of your food
msc += $item_dmg:rots? away
msc += $item_dmg:It has a very clean taste
msc += $item_dmg:You feel your flesh rotting away
msc += $item_dmg:You are engulfed in dark miasma
msc += $item_dmg:You feel very guilty
msc += $item_dmg:Done waiting
msc += $item_dmg:That really hurt
msc += $item_dmg:You fall into the water
msc += $item_dmg:PTOANNNG
msc += $item_dmg:PANG
msc += $item_dmg:GONNNNG
msc += $item_dmg:BOUMMMMG
msc += $item_dmg:SHROANNG
msc += $item_dmg:BONNNG
msc ^= $item_dmg:This attack would place you under penance
msc += $item_dmg:You will pay for your transgression\, mortal
msc += $item_dmg:You hear a distant slurping noise
msc ^= $item_dmg:picks up.*(potions?|scrolls?|wand)
msc += $item_dmg:drinks a potion
msc += $item_dmg:You hear a zap
msc += $item_dmg:reads a scroll
msc += $item_dmg:Mutagenic energies flood into your body
msc += $item_dmg:your body twists? and deforms?
msc += $item_dmg:You really shouldn't be using
msc += $item_dmg:You die.
msc += $item_dmg:You are engulfed in mutagenic fog
msc += $item_dmg:Your vision blurs
msc += $item_dmg:You feel frail
msc += $item_dmg:the book crumbles to dust
msc += $item_dmg:Your thinking seems confused
msc += $item_dmg:You are heavily infused with residual magics
msc += $item_dmg:You no longer feel (cold|heat) resistant
msc += $item_dmg:You feel less (cold|heat) resistant
msc += $item_dmg:You feel vulnerable to (cold|heat)
msc += $item_dmg:You feel less resistant to poisons
msc += $item_dmg:You no longer feel resistant to poison
msc += $item_dmg:Your vision seems duller
msc += $item_dmg:You feel less energetic
msc += $item_dmg:You shed all your fur
msc += $item_dmg:You begin to rot
msc += $item_dmg:Your tentacle spike disappears
msc += $item_dmg:You feel less repulsive
msc += $item_dmg:The jelly growth is reabsorbed into your body
msc += $item_dmg:Your pseudopods become smaller

# Warning Messages
msc ^= $warning:Creating passages of Golubria requires sufficient empty space
msc += $warning:You yowl
msc += $warning:You scream at
msc += $warning:is no longer covered in acid
msc += $warning:is no longer distracted by gold
msc += $warning:boulder beetle smashes into something
msc += $warning:grate falls apart
msc += $warning:Your passage of Golubria closes with a snap
msc += $warning:is no longer weakened
msc += $warning:Something blocks
msc += $warning:You feel jittery
msc += $warning:Your aim is not that steady anymore
msc += $warning:You feel strangely alone
msc += $warning:You feel the tide rushing in
msc += $warning:Failed to move towards target
msc += $warning:Your protection from physical attacks is fading
msc ^= $warning:The Screaming Sword
msc += $warning:A large net falls onto you
msc += $warning:You stop recalling your allies
msc += $warning:You feel a little guilty
msc += $warning:snaps.*out of.*fear
msc += $warning:Your stasis keeps you stable
msc += $warning:You retract your mandibles
msc += $warning:The boots cling to your feet
msc ^= $warning:Your ring of flames is guttering out
msc += $warning:reforms as a
msc += $warning:You draw the first five cards.*and discard the rest
msc += $warning:You have damaged your brain
msc += $warning:A thin mist springs up around you
msc += $warning:The mangrove smolders and burns
msc += $warning:You feel your anger subside
msc += $warning:You feel nervous for a moment
msc += $warning:Your.*is burned terribly
msc += $warning:Your.*is frozen
msc += $warning:There is nothing there\, so you fail to move
msc += $warning:You enter the passage of Golubria
msc += $warning:You start to feel a little slower
msc += $warning:drowns your?
msc += $warning:puts on a
msc += $warning:Faint laughter comes from somewhere
msc += $warning:shroud bends your.*attack away
msc += $warning:shadowy figures dance through the air in front of you
msc += $warning:This room is filled with shadowy figures
msc += $warning:You feel spirits watching over you
msc += $warning:You feel a genetic drift
msc += $warning:You return to the normal time flow
msc ^= $warning:The corpse rots
msc ^= $warning:You finish butchering the rotting
msc += $warning:reappears nearby
msc += $warning:I'll put it outside for you
msc += $warning:A pair of horns grows on your head
msc += $warning:is held in a (net|web)
msc += $warning:Smoke pours forth from your.*of chaos
msc += $warning:You cannot go berserk while under stasis
msc += $warning:You feel less woody
msc += $warning:is no longer paralysed
msc += $warning:The antennae on your head shrink away
msc += $warning:You feel less stealthy
msc += $warning:falls into the lava
msc ^= $warning:Your spellforged servitor disappears
msc += $warning:This weapon is vampiric, and you must be Full or above to equip it
msc += $warning:The shock serpent's electric aura discharges
msc += $warning:The air sparks with electricity
msc += $warning:The cursed.*is stuck to you
msc += $warning:You cannot enchant this weapon
msc += $warning:You sense an evil presence
msc += $warning:Jory draws you further into his thrall
msc += $warning:grabs your
msc += $warning:You shudder from the earth-shattering force
msc += $warning:Smoke pours from your
msc += $warning:curses noisily
msc += $warning:is no longer blind
msc += $warning:Lightning arcs down from a storm cloud
msc += $warning:You feel strangely numb
msc += $warning:You feel less sure on your feet
msc += $warning:The air around you crackles with electrical energy
msc += $warning:The vortex of raging winds lifts you up
msc += $warning:creates a blast of rain
msc += $warning:shimmers and seems to become two
msc += $warning:Your ball lightning explodes
msc += $warning:There is a sudden explosion of flames
msc += $warning:You feel extremely nervous for a moment
msc += $warning:The orb fizzles
msc += $warning:A film of ice covers the
msc += $warning:That ambrosia tasted strange
msc += $warning:orb of destruction hits.*wall
msc += $warning:Something tries to affect you
msc += $warning:You block its attack
msc += $warning:A large net falls down
msc += $warning:You have made a black mistake
msc += $warning:You are stuck in your current form
msc += $warning:You feel like a pig
msc += $warning:Your hearing returns
msc += $warning:You feel less in control of your magic
msc += $warning:You feel your magical power running wild
msc += $warning:are frozen
msc += $warning:Something hits you but does no damage
msc += $warning:You turn into a bat
msc += $warning:A demon appears
msc += $warning:twists and deforms
msc += $warning:There is a sudden blast of acid
msc += $warning:Die\, mortal
msc += $warning:You choke on the stench
msc += $warning:Your summoned allies are left behind
msc += $warning:You feel that your aim is more steady
msc += $warning:There's a creature in the
msc += $warning:They are\:
msc += $warning:A card falls out of the deck
msc += $warning:(dart|javelin|large rock|stone|tomahawk) disappears in a puff of smoke
msc += $warning:You can't close doors while held in a net
msc += $warning:A slime creature suddenly
msc += $warning:You feel closer to the material plane
msc += $warning:leaps out from its hiding place
msc += $warning:The cursed.*is stuck to your body
msc += $warning:You stop removing your armour
msc += $warning:You smell decay
msc += $warning:You feel a malignant aura surround you
msc += $warning:briefly surrounded by a scintillating aura of random colours
msc += $warning:looks stronger
msc += $warning:You have difficulty breathing
msc += $warning:The heat melts your.*(armour|shield)
msc += $warning:You are engulfed in a cloud of spores
msc += $warning:You feel less perceptive
msc += $warning:A profound silence engulfs you
msc += $warning:An unnatural silence engulfs you
msc ^= $warning:Hurry and find it before the entrance collapses
msc += $warning:Your memory of.*unravels
msc += $warning:You speak a Word of immense power
msc += $warning:seems to move somewhat quicker
msc += $warning:steals.*your
msc += $warning:A tentacle flies out from the starspawn's body
msc += $warning:The explosive bolt releases an explosion
msc += $warning:There is a Zot trap here
msc += $warning:You enter a teleport trap
msc += $warning:You need to enable at least one skill for training
msc += $warning:You (resume|stop) training
msc += $warning:You feel slightly jumpy
msc += $warning:You are splashed with acid
msc += $warning:ticking.*clock
msc += $warning:dying ticks
msc += $warning:distant snort
msc += $warning:odd grinding sound
msc += $warning:creaking of ancient gears
msc += $warning:floor suddenly vibrates
msc += $warning:a sudden draft
msc += $warning:coins.*counted
msc += $warning:tolling.*bell
msc += $warning:fails to return
msc += $warning:Something appears in a flash of light
msc += $warning:you turn into a fiery being
msc += $warning:no longer ripe
msc += $warning:The wave splashes down
msc += $warning:The spell fizzles
msc += $warning:Your body armour is too heavy
msc += $warning:The crackling of melting ice is subsiding rapidly
msc += $warning:seems to gain new vigour
msc += $warning:You feel strangely stable
msc += $warning:(asks|barks|bellows|boasts|brags|breathes|buzzes|cackles|calls|caws|chants|cheers)
msc += $warning:(chilling moan|complains|cries|croak|curses loudly|embarks|explains|Floosh|gibbers|giggles)
msc += $warning:(grits|groans|growls|grumbles|grunts|gurgles|hisses|jeers|keens|laughs|launches|makes a sound)
msc += $warning:(mewls|moans|mumbles|murmurs|mutters|pleads|prattles|preaches|queries|recites|roars|says)
msc += $warning:(scowls|screams|screeches|shout|shriek|sighs|sings|snarls|sneers|snorts|threatens|trumpets)
msc += $warning:(utters an oath|wail|wails|whimpers|whisper|yells)
msc += $warning:you (roar|yell|hiss)
msc += $warning:imitates the bagpipes
msc += $warning:looks more energetic
msc += $warning:suddenly curses
msc += $warning:Dowan breathes
msc += $warning:Dowan shakes his head\, saying\, \"No\, no\, no!\"
msc += $warning:You hear strange voices
msc += $warning:You hear
msc += $warning:You drop
msc += $warning:You hear an irritating high-pitched whine
msc += $warning:You hear snatches of song
msc += $warning:seems more stable
msc += $warning:opens the (door|gate|large door|huge gate)
msc += $warning:dissolves into sparkling lights
msc += $warning:[^un]wields
msc += $warning:There is a portal leading out of here
msc += $warning:Natasha's spirit plunges in to the ground
msc += $warning:Natasha's spirit rises from its lifeless body
msc += $warning:wears
msc += $warning:You are.*contaminated
msc += $warning:blinks
msc += $warning:You are starting to lose your buoyancy
msc += $warning:You float gracefully downwards
msc += $warning:Your surroundings suddenly seem different
msc += $warning:You feel your bond with your spectral weapon wane
msc += $warning:It (begins to drip with poison|bursts into flame|glows with a cold blue light|softly glows with a divine radiance|stops glowing)
msc += $warning:Your.*drips with poison
msc += $warning:You sense an unholy aura
msc += $warning:It is covered in frost
msc += $warning:The shock serpent begins to gather electrical charge
msc += $warning:moves out of view
msc += $warning:basks in the mutagenic energy
msc += $warning:Several doors burst open
msc += $warning:Flickering shadows surround you
msc += $warning:You found a.*trap
msc += $warning:You.*one of the.*heads off
msc += $warning:slime creatures merge
msc += $warning:roars a battle-cry
msc += $warning:The.*is healed
msc += $warning:You stumble backwards
msc += $warning:Are you sure you want to stumble around while confused
msc += $warning:it creaks loudly
msc += $warning:The.*explodes
msc += $warning:You are caught in (a fiery explosion|an explosion of ice and frost)
msc += $warning:stops burning
msc += $warning:(The |.*)is healed
msc += $warning:You stop butchering
msc += $warning:You feel less studious
msc += $warning:(corpses?|macabre mass) merges with
msc += $warning:You start to feel a little uncertain
msc += $warning:corpses? begins to drag
msc += $warning:corpses meld into an agglomeration of writhing flesh
msc += $warning:beckons forth a restless soul
msc += $warning:Something reaches out for you
msc += $warning:Something tries to feed on your intellect
msc += $warning:You feel a brief urge to hack something to bits
msc += $warning:Pain shudders through your
msc += $warning:The.*passes through your shield
msc += $warning:draws strength from your injuries
msc += $warning:The.*pierces through
msc += $warning:The forest fire spreads
msc += $warning:The tree burns like a torch
msc += $warning:magical defenses are stripped away
msc += $warning:You blink
msc += $warning:You teleport
msc += $warning:You step into.*shadow
msc += $warning:Grasping roots rise from the ground around the
msc += $warning:The winds start to flow at the.*will
msc += $warning:The .*(are|is) blown away
msc += $warning:goes into a frenzy at the smell of blood
msc += $warning:Something picks up
msc += $warning:You smell burning wood
msc += $warning:stumbles backwards
msc += $warning:looks slightly unstable
msc += $warning:slips into darkness
msc += $warning:The air around.*erupts in flames
msc += $warning:hops backward while attacking
msc += $warning:violent explosion of flames
msc += $warning:turns its malign attention towards you
msc += $warning:Splash!
msc += $warning:Harold gasps with his last breath
msc += $warning:You enter the shallow water
msc += $warning:You see a puff of smoke
msc += $warning:pour from your
msc += $warning:Tentacles burst out of the water
msc += $warning:calls forth a grand avatar
msc += $warning:focuses on the pain
msc += $warning:suddenly seems more agile
msc += $warning:regenerates before your eyes
msc += $warning:You feel corrupt for a moment
msc += $warning:Send 'em back where they came from
msc += $warning:The net rips apart
msc += $warning:Your surroundings seem slightly different
msc += $warning:You are under the weather
msc += $warning:You are standing in the rain
msc += $warning:The rain has left you waist-deep in water
msc += $warning:We do not forgive those who trespass against us
msc += $warning:A.*appears from out of thin air
msc += $warning:looks more healthy
msc += $warning:A mysterious force pulls you upwards
msc += $warning:punctures the fabric of the universe
msc += $warning:degenerates into a cloud
msc += $warning:wounds heal themselves
msc += $warning:is no longer moving slowly
msc += $warning:is completely healed
msc += $warning:You heal
msc += $warning:It is briefly surrounded by a scintillating aura of random colours
msc += $warning:Partly explored
msc += $warning:There is a shaft here
msc += $warning:Dowan seems overcome with grief, but rights himself reflexively soon after
msc += $warning:You feel that this wand is rather unreliable
msc += $warning:You feel less protected
msc += $warning:You hear a crashing sound
msc += $warning:shatters
msc += $warning:apparitions take form around you
msc += $warning:You feel your magic capacity is already quite full
msc += $warning:You feel vulnerable
msc += $warning:pulls away from the web
msc += $warning:withdraws into its
msc += $warning:is no longer petrified
msc += $warning:You remove
msc += $warning:Your.*dissolves into shadows
msc += $warning:Your.*stops moving altogether
msc += $warning:hides itself under the floor
msc += $warning:puts on a burst of speed
msc += $warning:decay slows
msc += $warning:Your.*is caught in
msc += $warning:Thorny briars emerge from the ground!
msc += $warning:You flicker for a moment
msc += $warning:There is a.*altar.*here
msc += $warning:You kneel at the altar
msc += $warning:You start to feel less resistant
msc += $warning:You feel a strong urge to attack something
msc += $warning:You cannot move away from
msc += $warning:The pull of.*song draws you forwards
msc += $warning:Shadowy forms rise from the deep
msc += $warning:You feel as though you will be slow longer
msc += $warning:disappears!
msc += $warning:Your.*is no longer moving quickly
msc += $warning:You feel your magic capacity decrease
msc += $warning:drains the heat from the surrounding environment
msc += $warning:pounces on you
msc += $warning:A tentacle rises from the water
msc += $warning:comes (down|up) the stairs
msc += $warning:You catch a bit of a chill
msc += $warning:A ballistomycete grows in the wake of the spore
msc += $warning:A fungus suddenly grows
msc += $warning:A toadstool grows
msc += $warning:then quickly surges around you
msc += $warning:There is a sudden explosion of frost
msc += $warning:That was not very filling
msc += $warning:You failed to disarm the trap
msc += $warning:is covered with a thin layer of ice
msc += $warning:draws out.*weapon's spirit
msc += $warning:You are pushed out
msc ^= $warning:Your.*seems to slow down
msc += $warning:thirsts for the lives of mortals
msc += $warning:emits a brilliant flash of light
msc += $warning:is firebranded into
msc += $warning:is no longer bleeding
msc += $warning:The dungeon rumbles around Jorgrun!
msc += $warning:evaporates and reforms as
msc += $warning:You turn into a venomous arachnid creature
msc += $warning:infuriates you
msc += $warning:Your extra speed is starting to run out
msc += $warning:Your skin is crawling a little less now
msc += $warning:You stumble into the trap
msc += $warning:Your transformation is almost over
msc += $warning:You feel magic leave you
msc += $warning:You feel magic returning to you
msc += $warning:Your (horns|talons) disappear
msc += $warning:Tentacles burst from the starspawn
msc += $warning:you must find a gate leading back
msc += $warning:You fall off the wall
msc += $warning:Blech - you need (greens|meat)
msc += $warning:A starcursed mass splits
msc += $warning:You draw the Sage
msc += $warning:You feel a wave of frost pass over you
msc += $warning:The creatures around you are filled with an inner flame
msc += $warning:is filled with an inner flame
msc += $warning:You feel less healthy
msc += $warning:summons a great blast of wind
msc += $warning:You feel less resistant to hostile enchantments
msc += $warning:Your attack snaps.*out of its fear
msc += $warning:You feel blessed for a moment
msc += $warning:You draw a card
msc += $warning:Walls emerge from the floor
msc += $warning:You feel like more of a target
msc += $warning:is knocked back by the flood of elemental water
msc += $warning:blown away by the wind
msc += $warning:is surrounded by Orcish apparitions
msc += $warning:The.*reappears nearby
msc += $warning:The deck of cards disappears
msc += $warning:The.*looks more experienced
msc += $warning:There is a rocky tunnel leading out of this place here
msc += $warning:Your icy (armour|shield) starts to melt
msc += $warning:Your legs become a tail
msc += $warning:You feel the effects of Trog's Hand fading
msc += $warning:You slam the door shut with a bang
msc += $warning:This armour is.*for you
msc += $warning:magical effects unravel
msc += $warning:You awkwardly throw
msc += $warning:You erupt
msc += $warning:The flames covering.*go out
msc += $warning:bleats in terror
msc += $warning:seems to regain.*courage
msc += $warning:You have a feeling of ineptitude
msc += $warning:falls through a shaft
msc += $warning:You cannot throw anything while held in a net
msc += $warning:furiously retaliates
msc += $warning:The blast of chaos engulfs your?
msc += $warning:You are engulfed in seething chaos
msc += $warning:Your song is almost over
msc += $warning:is in the way
msc += $warning:You are too berserk
msc += $warning:The tentacle pulls you backwards
msc += $warning:starcursed mass shudders and
msc += $warning:The kraken squirts a massive cloud of ink
msc += $warning:Wisps of shadow whirl around
msc += $warning:You are too injured to fight recklessly
msc += $warning:shakes off its lethargy
msc += $warning:I don't know how to get there
msc += $warning:Your.*warbles
msc += $warning:chimes melodiously
msc += $warning:erupts into laughter
msc += $warning:makes a deep moaning sound
msc += $warning:raves incoherently
msc += $warning:speaks gibberish
msc += $warning:belts out
msc += $warning:yelps
msc += $warning:goes tick-tock
msc += $warning:gives off a wolf whistle
msc ^= $warning:[e] your.* of resist
msc += $warning:phases out as you
msc += $warning:momentarily phases out
msc += $warning:cracks jokes
msc += $warning:Your orb of destruction dissipates
msc += $warning:regales you with its life story
msc += $warning:parrots the noises around you
msc += $warning:lets out a mournful sigh
msc += $warning:tootles away
msc += $warning:makes a horrible noise
msc += $warning:burps loudly
msc += $warning:You are caught in a violent explosion
msc += $warning:pulses with an eldritch light
msc += $warning:the glow from your magical contamination prevents you from becoming completely invisible
msc += $warning:appears from out of your range of vision
msc += $warning:You stop putting on your armour
msc += $warning:We have you now
msc += $warning:You do not belong in this place
msc += $warning:before it is too late
msc += $warning:There is a sudden explosion of magical energy
msc += $warning:Something forms from out of thin air
msc += $warning:You sense a hostile presence
msc += $warning:Trespassers are not welcome here
msc += $warning:You feel a terrible foreboding
msc += $warning:You will not leave this place
msc += $warning:wrenching scream
msc += $warning:Leave now/, before it is too late
msc += $warning:picks up
msc += $warning:Nothing appears to happen
msc += $warning:The dead are
msc += $warning:The boulder beetle hits a closed door
msc += $warning:begin to drag.*along the ground
msc += $warning:merge to form a (large abomination|macabre mass|small abomination)
msc += $warning:Two macabre masses merge
msc += $warning:falls through the shaft
msc += $warning:There is a crawl-hole back to the Lair here
msc += $warning:There is a hole to the Spider Nest here
msc += $warning:You create a pond
msc += $warning:Mennas becomes audible again
msc += $warning:That was extremely unsatisfying
msc += $warning:The wind howls around you
msc += $warning:You are feeling less magically infused
msc += $warning:Something invisible bursts forth from the water
msc += $warning:Something.*misses
msc += $warning:There is a cloud of mutagenic fog here
msc += $warning:howls
msc += $warning:You part the fleshy orifice with a squelch
msc += $warning:The orb of energy explodes
msc += $warning:The air shimmers briefly around you
msc += $warning:You are much too full right now
msc += $warning:turns to fight
msc += $warning:You feel transcendent for a moment
msc += $warning:You're too terrified to move while being watched
msc += $warning:The weapon returns to the
msc += $warning:The queen bee calls on the killer bee to defend her
msc += $warning:You turn into a bat
msc += $warning:Your.*looks incredibly listless
msc += $warning:The mass is resisting your pull
msc += $warning:Moving in this stuff is going to be slow
msc += $warning:escapes
msc += $warning:The silence causes your song to end
msc += $warning:You feel (slightly|somewhat) less full
msc += $warning:The light of Elyvilon fails to reach
msc += $warning:The light of Elyvilon almost touches upon
msc += $warning:[^r]pulls free of the water
msc += $warning:Your piety has decreased
msc += $warning:struggles to resist
msc += $warning:You feel.*more hungry
msc += $warning:You are outlined in light
msc += $warning:Your.*is outlined in light
msc += $warning:You feel momentarily disoriented
msc += $warning:You are now empty
msc += $warning:(prevent|prevents) you from hitting
msc += $warning:The water nymph flows with the water
msc += $warning:summons a
msc += $warning:cannot make way for you
msc += $warning:The horns on your head shrink away
msc += $warning:Your shroud begins to fray at the edges
msc += $warning:You'd need three hands to do that
msc += $warning:Your.*disappears
msc += $warning:That's too.*for you
msc += $warning:The dungeon trembles and rubble falls from the walls
msc += $warning:Finesse? Hah! Time to rip out guts
msc += $warning:You fail to extend your transformation any further
msc += $warning:This spell does not affect your current form
msc += $warning:You can't wield anything in your present form
msc += $warning:Your.*revert to their normal proportions
msc += $warning:Suddenly Natasha's spirit rises from her lifeless body
msc += $warning:Your.*shudders
# Demonspawn gaining a mutation they already have
msc += $warning:Your mutations feel more permanent
msc += $warning:Roots rise up from beneath.*and drag it to the ground
msc ^= $warning:You hunger for vegetation
msc ^= $warning:You feel a sudden chill
msc += $warning:You feel hot for a moment
msc += $warning:stop glowing
msc += $warning:The water foams
msc += $warning:The satyr's allies are stirred to greatness
msc += $warning:Mushrooms sprout up around you
msc += $warning:seems less confused
msc += $warning:You could not reach far enough
msc ^= $warning:The golden flame engulfs you
msc += $warning:You shudder
msc += $warning:The giant firefly flashes a warning beacon
msc += $warning:vibrate crazily for a second
msc += $warning:Harold falls down\, and clutches his wounds
msc += $warning:You finish recalling your allies
msc += $warning:Your.*wears
msc += $warning:Something (bites|hits) your?
msc += $warning:You feel more confident with your borrowed prowess
msc += $warning:Your hands get new energy
msc += $warning:You squeal for attention
msc ^= $warning:changes into
msc += $warning:The crackle of the magical portal is almost imperceptible now
msc += $warning:blocks (the|you)
msc += $warning:You start to feel a little faster
msc += $warning:You meow for attention
msc += $warning:The lightning arc arcs out of your line of sight
msc += $warning:The lightning arc suddenly appears
msc += $warning:The bush is engulfed in roaring flames
msc += $warning:A yell rips itself from your throat
msc += $warning:Purgy wonders\, \"What am I doing in here\?\"
msc += $warning:Your spectral.*fades into mist
msc += $warning:You create some ball lightning
msc += $warning:dances into the air
msc += $warning:appears
msc += $warning:Your divine protection wanes
msc += $warning:The sheep \"Baaaas\" balefully
msc += $warning:is blown backwards by the freezing wind
msc += $warning:Your connection to magic feels (subdued|more subdued|nearly dormant)
msc += $warning:You feel a numb sensation
msc += $warning:Your skull pulses and throbs
msc += $warning:Seething terrors besiege your sanity
msc += $warning:your eldritch tentacle is severed
msc += $warning:You sink to the bottom

# Boring Messages
msc += $boring:Your tentacles glow momentarily
msc += $boring:tentacles wither and die
msc += $boring:You feel a little dazed
msc += $boring:You feel mildly nauseous
msc += $boring:looks momentarily confused
msc += $boring:Motes of dust swirl before your eyes
msc ^= $boring:You squeeze the fleshy orifice shut
msc += $boring:Gastronok glows a brilliant shade of cerise
msc += $boring:fingertips start to glow
msc += $boring:eyes start to glow
msc += $boring:You smell tea
msc += $boring:Your ghoul eats
msc += $boring:seems to dim momentarily
msc += $boring:The net is caught on your fulminant prism
msc += $boring:The shadows disperse without effect
msc += $boring:You feel woody for a moment
msc += $boring:Your vision is briefly tinged with green
msc ^= $boring:Sigmund is suddenly surrounded by pale red light
msc += $boring:has a weird expression for a moment
msc += $boring:You feel roots moving beneath the ground
msc += $boring:This spell is already in effect
msc ^= $boring:You displace your
msc ^= $boring:whispers something so quietly that you cannot hear
msc ^= $boring:for a moment.*blends into the shadows
msc ^= $boring:picks up a beetle and eats it
msc += $boring:Everything looks hazy for a moment
msc += $boring:There is a strange surge of energy around
msc += $boring:orc priest shimmers for a moment
msc += $boring:orc priest's eyes start to glow
msc += $boring:The weapon returns to your
msc += $boring:Your bandages flutter
msc += $boring:The water in the fountain briefly bubbles
msc += $boring:The bush looks momentarily different
msc += $boring:Dowan's feet meld with the ground\, briefly
msc += $boring:briefly looks nauseous
msc += $boring:twitches
msc += $boring:Jessica looks very angry
msc += $boring:You fall off the door
msc += $boring:as though insubstantial
msc += $boring:The Killer Klown sprays water
msc += $boring:The Killer Klown honks
msc += $boring:wriggles its tentacles
msc += $boring:You reach down and part the fleshy orifice
msc += $boring:orb spider pulsates with a strange energy
msc += $boring:orb spider begins to weave its threads into a brightly glowing ball
msc += $boring:Your eyebrows briefly feel incredibly bushy
msc += $boring:briefly appears rusty
msc += $boring:Your.*stops glowing
msc += $boring:Your.*briefly vibrates
msc += $boring:You feel gritty
msc += $boring:You briefly become tangled in your
msc += $boring:Your eyebrows wriggle
msc += $boring:You detect nothing
msc += $boring:Your.*shimmers for a moment
msc += $boring:Your.*eyes start to glow
msc += $boring:Your.*spins!
msc += $boring:grins madly
msc += $boring:You lose your grip on
msc += $boring:The water engulfing you falls away
msc += $boring:The disc glows for a moment
msc += $boring:Your.*briefly glows
msc += $boring:You feel numb
msc += $boring:The chaos spawn grows dozens of eye stalks in order to get a better look at you
msc += $boring:Jory stares carefully at you
msc += $boring:seems to be having trouble coordinating.*its legs
msc += $boring:Your.*flashes
msc += $boring:You create a blast of thin mist
msc ^= $boring:then vanish
msc += $boring:avoids triggering.*trap
msc += $boring:Terence looks scornfully at you
msc += $boring:Sigmund looks at you with fury
msc += $boring:holds.*ground
msc += $boring:The door collapses
msc += $boring:You smell baking bread
msc += $boring:The lightning arc grounds out
msc += $boring:Fannar glares icily
msc ^= $boring:A poisoned needle shoots out and hits your shield
msc += $boring:ghost twirls its
msc += $boring:You attack empty space
msc += $boring:Eustachio twirls his moustache
msc += $boring:is briefly tinged with black
msc += $boring:The dust glows
msc += $boring:Crazy Yiuf scratches his head thoughtfully
msc += $boring:Crazy Yiuf counts something out on his finger
msc += $boring:You aren't quite hungry enough to eat that
msc += $boring:The crystal guardian glitters
msc += $boring:The wizard's fingertips start to glow
msc += $boring:You are already empty-
msc ^= $boring:the.*shaped block of ice
msc ^= $boring:briefly gains? a (green|red|yellow) sheen
msc += $boring:The great wave of water passes through the water elemental
msc += $boring:shimmers and vanishes
msc += $boring:You do an impromptu tapdance
msc += $boring:You feel uncomfortable
msc ^= $boring:The shadow imp breathes mist at you
msc += $boring:That snozzcumber tasted truly putrid
msc += $boring:The reaper draws a finger across its throat
msc += $boring:Your.*seems to dim momentarily
msc += $boring:Your.*is briefly tinged with black
msc += $boring:Your.*shivers with cold
msc += $boring:Your.*has a weird expression for a moment
msc += $boring:A malignant aura surrounds your
msc += $boring:Your.*twitches violently
msc += $boring:The world appears momentarily distorted
msc += $boring:The iron imp grinds its teeth
msc += $boring:unwise to walk into this
msc += $boring:The tree breaks and falls down
msc += $boring:Nessos tries to tell you a complicated story about hydras
msc += $boring:You feel blessed for a moment
msc += $boring:The boulder beetle hits.*wall
msc += $boring:A root reaches out and grasps at passing movement
msc += $boring:Tangled roots snake along the ground
msc += $boring:You smell coffee
msc += $boring:The white imp grinds its teeth
msc += $boring:Your.*imp grins impishly at you
msc += $boring:Your hooves feel warm
msc += $boring:Your.*jumps up and down with excitement
msc += $boring:Strange appendages sprout from
msc += $boring:Suppurating sores blossom under
msc += $boring:That beef jerky was jerk
msc += $boring:A dozen eyes blink open in the
msc += $boring:You part the fleshy orifice
msc += $boring:There is an open fleshy orifice here
msc += $boring:Your hair momentarily turns into snakes
msc += $boring:The crimson imp grinds its teeth
msc ^= $boring:The crimson imp spits at you
msc += $boring:then rights herself and shakes her weapon
msc += $boring:You smell burning hair
msc += $boring:Your nose twitches suddenly
msc += $boring:You are wearing that object
msc += $boring:You can't wield jewellery
msc += $boring:There is an abandoned shop here
msc += $boring:You don't have any such object
msc += $boring:Mennas is caught in a moment of prayer
msc += $boring:You spin around
msc += $boring:Aizul coils and then uncoils
msc += $boring:The tide is released from Ilsuiw's call
msc += $boring:Polyphemus seems to be sizing you up for his next meal
msc += $boring:You can't read that
msc += $boring:You can't drink that
msc += $boring:Your.*falls into the water
msc += $boring:A large abomination twists grotesquely
msc += $boring:collapse into pulpy
msc ^= $boring:You reach to attack
msc += $boring:avoids the shaft
msc += $boring:Your bones ache
msc += $boring:Thank you for shopping
msc += $boring:Your ears itch
msc += $boring:Prince Ribbit hops awkwardly around
msc += $boring:You pass into a different region of Pandemonium
msc += $boring:You smell brimstone
msc += $boring:Something frightening happens
msc += $boring:Multicoloured lights dance before your eyes
msc += $boring:Some snowflakes condense on Fannar
msc += $boring:shape twists and changes as it dies
msc += $boring:No such ability
msc += $boring:The plume of ash settles
msc += $boring:You feel uncomfortably hot
msc += $boring:You can't wield that with a shield
msc ^= $boring:The blast of magma explodes
msc += $boring:Crazy Yiuf glowers
msc += $boring:Crazy Yiuf flaps his cloak
msc += $boring:Crazy Yiuf waves his quarterstaff at you
msc += $boring:You feel lost and a long
msc += $boring:The world around you seems to dim momentarily
msc += $boring:tears through a web
msc += $boring:Pikel waves his whip at you
msc += $boring:Wisps of condensation drift from your
msc += $boring:A chill runs through your body
msc += $boring:Frost covers your body
msc += $boring:numb with cold
msc += $boring:That.*was very bland
msc += $boring:That lemon was rather sour
msc += $boring:You call on the dead to rise
msc += $boring:You can't wear that
msc += $boring:vibrates crazily for a second
msc ^= $boring:The crimson imp breathes (mist|steam) at you
msc += $boring:showing sharp teeth
msc += $boring:Branches wave dangerously above you
msc += $boring:A root lunges up near you
msc += $boring:Maurice looks sneaky
msc += $boring:Suddenly you are surrounded with a pale green light
msc += $boring:really hit the spot
msc += $boring:Mmmm... Yummy
msc += $boring:Grum bares his teeth
msc += $boring:Grum sniffs the air and quickly glances around
msc += $boring:The shadow imp grinds its teeth
msc += $boring:looks to the heavens
msc += $boring:beckons to you
msc += $boring:Your.*struggles to escape
msc += $boring:Your.*struggles against
msc += $boring:Your.*struggles to get unstuck from
msc += $boring:fades away
msc += $boring:You feel electric
msc += $boring:sharp shower of sparks
msc += $boring:pulsates ominously
msc += $boring:You feel earthy
msc += $boring:Sparks of electricity dance between your
msc += $boring:Edmund gestures with his flail
msc += $boring:You feel very uncomfortable
msc += $boring:tastes (good|great|unpleasant|very good)
msc += $boring:is not very appetising
msc += $boring:was delicious
msc += $boring:Xtahua glares at you
msc += $boring:You pass through the gate
msc += $boring:The starspawn's tentacles wither and die
msc += $boring:Trunks creak and shift
msc += $boring:unmelds from your body
msc += $boring:The air around.*crackles with energy
msc += $boring:Something.*the (bush|plant)
msc += $boring:There's nothing there!
msc += $boring:You briefly turn translucent
msc += $boring:unborn seems to be listening
msc += $boring:You can only put on jewellery
msc ^= $boring:You smell decay. Yuck!
msc += $boring:Ouch!
msc += $boring:There isn't anything here
msc += $boring:The air around you briefly surges with heat
msc += $boring:Your skin glows momentarily
msc += $boring:You draw two cards from the deck
msc += $boring:You shuffle the cards back into the deck
msc += $boring:The drowned soul returns to the deep
msc += $boring:Your.*stays? behind
msc += $boring:You prostrate yourself
msc += $boring:You shiver with cold
msc += $boring:glows? (bright chartreuse|bright red|brightly|brilliant black|brilliant cobalt blue) for a moment
msc += $boring:glows? (brilliant magenta|brilliant silver|dark black|dark umber|dull charcoal|dull rubric) for a moment
msc += $boring:glows? (dull silver|faint lavender|faint lime green|mottled black|pale dun|pale gold|pale silver) for a moment
msc += $boring:glows? (pale yellow|shimmering blue|shimmering brown|shimmering rubric|shining black|shining brown|silvery red) for a moment
msc += $boring:Waves of light ripple over
msc += $boring:Your skin tingles
msc += $boring:looks braver
msc += $boring:You enjoyed that
msc += $boring:Your brain hurts
msc += $boring:becomes somewhat translucent
msc += $boring:generates a fountain of clear water
msc += $boring:You cannot attack while caught
msc += $boring:You cannot throw anything while caught
msc += $boring:grinds (her|his) teeth
msc += $boring:bristles in rage as it notices you
msc += $boring:You feel forgetful for a moment
msc += $boring:The briar patch crumbles away
msc += $boring:You feel momentarily lethargic
msc += $boring:...but nothing happens
msc += $boring:Wisps of smoke drift from your
msc += $boring:You smell salt
msc += $boring:tries to hide in the shadows
msc += $boring:stops crackling
msc ^= $boring:Your.*is no longer covered in acid
msc += $boring:You momentarily stiffen
msc += $boring:waves its rhizomes
msc += $boring:The flesh is too rotten for a proper zombie
msc += $boring:You smell (smoke|something weird)
msc += $boring:The floor shifts beneath you alarmingly
msc += $boring:The reaper smiles without lips
msc += $boring:great wave of water passes through
msc += $boring:There isn't anything to butcher here
msc += $boring:crushes a nearby insect and laughs
msc += $boring:Welcome back to the Dungeon
msc += $boring:You are blasted with air
msc ^= $boring:There is a collapsed entrance here
msc += $boring:You feel slightly nauseous
msc += $boring:You can't see any susceptible monsters within range! (Use Z to cast anyway.)
msc += $boring:You can't go (down|up) here
msc += $boring:Your hair stands on end
msc += $boring:Wisps of vapour drift from your
msc += $boring:The Killer Klown smiles at you
msc += $boring:the (bush|fungus|plant)
msc += $boring:You are momentarily dazzled by a (brilliant|flash of) light
msc ^= $boring:(flickers out of sight|flickers and vanishes|slips into darkness) for a moment
msc += $boring:The golden flame engulfs your?
msc += $boring:The shaft crumbles and collapses
msc += $boring:An air elemental (forms|merges) itself (from|into) the air
msc += $boring:A corpse collapses into a pulpy mess
msc += $boring:You start (resting|waiting)
msc += $boring:Unknown command
msc += $boring:but (do no|doesn't do any|does no) damage
msc += $boring:miss
msc += $boring:Wisps of poison gas drift from your
msc += $boring:You walk carefully through
msc += $boring:grow from
msc += $boring:withers and dies
msc += $boring:There is nothing on the other side of the stone arch
msc += $boring:misses you
msc += $boring:You are waved at by a branch
msc += $boring:The trees move their gnarly branches around
msc += $boring:You swap
msc += $boring:The smell of rotting flesh
msc += $boring:Ugh! There is something really disgusting
msc += $boring:Heat runs through your body
msc += $boring:Lukewarm flames ripple over your body
msc += $boring:stops (dripping with poison|flaming)
msc += $boring:Press } to see all runes
msc += $boring:There is a.*(door|gate)
msc += $boring:(antennae|eye-stalks|whiskers)
msc += $boring:You feel troubled
msc += $boring:You feel a wave of unholy energy pass over you
msc += $boring:grins evilly
msc += $boring:A huge blade swings just past you
msc += $boring:(The|Something).*disappears
msc += $boring:The.*glitters chillingly
msc += $boring:You feel a strange surge of energy
msc += $boring:There are no unholy or evil weapons here to destroy
msc += $boring:close doors on yourself
msc += $boring:Your.*falls off the wall
msc += $boring:stops rolling
msc += $boring:(gazes forward|pauses|quivers|skips|sputters|stops to sniff|summons a swarm of flies)
msc += $boring:turns its.*gaze
msc += $boring:Your summoned ally is left behind
msc += $boring:That felt strangely unrewarding
msc += $boring:The air around you crackles with energy
msc += $boring:in your inventory have.*rotted away
msc += $boring:(drops|unwields)
msc += $boring:The battlesphere dissipates
msc += $boring:(The|Your?).*(passes|pick your way) through a web
msc += $boring:passes through a web
msc += $boring:You feel extremely cold
msc += $boring:You feel terrible
msc += $boring:You sense a malignant aura
msc += $boring:You (hold|stand) your ground
msc += $boring:Your.*(holds|stands) its ground
msc += $boring:The.*eats the
msc += $boring:The winds cease moving at the.*will
msc += $boring:The ground creaks as gnarled roots bulge its surface
msc += $boring:rages
msc += $boring:Your acid blob dissolves into a puddle of slime
msc += $boring:You feel a wrenching sensation
msc += $boring:The.*falls off the wall
msc += $boring:The.*jiggles
msc += $boring:The.*looks excited
msc += $boring:Pikel cracks his whip
msc += $boring:Press } to see all the runes you have collected
msc += $boring:slime creature splits
msc += $boring:stops glowing
msc += $boring:splashes around in the water
msc += $boring:tentacles slide back into the water
msc += $boring:The.*dissolves into shadows
msc += $boring:You smell something rotten
msc += $boring:You (close|open) the.*(door|gate)
msc += $boring:reach down and (close|open) the.*(door|gate)
msc += $boring:You (climb|fly) (down|up)wards
msc += $boring:You go (down|up)
msc += $boring:You fly (down|up) through the gate
msc += $boring:You must enter the number of times for the command to repeat
msc += $boring:Use Z to cast anyway
msc += $boring:There are no items here
msc += $boring:it crumbles to dust
msc += $boring:The hatch slams shut behind you
msc += $boring:There is an empty arch of ancient stone here
msc += $boring:The world spins around you as you enter the gateway
msc += $boring:This spell is.*dangerous to cast
msc += $boring:There is a web.*here
msc += $boring:You pick your way through the web
msc += $boring:You hold your ground
msc += $boring:The floor vibrates
msc += $boring:Sand pours from your
msc += $boring:Strange energies run through your body
msc += $boring:You smell something strange
msc += $boring:ghost tries to sneak away
msc += $boring:evades a web
msc += $boring:The.*goes (down|up) the
msc += $boring:jumps into the shaft
msc += $boring:Found.*gold
msc += $boring:You now have.*gold
msc += $boring:Why would you want to do that
msc += $boring:you're not good enough to have a special ability
msc += $boring:holds its.*at the ready
msc += $boring:There is a.*fountain.*here
msc += $boring:Little bolts of electricity crackle over the disc
msc += $boring:tries to grin evilly
msc += $boring:The corpses? collapses? into a pulpy mess
msc += $boring:There is an empty arch of ancient stone
msc += $boring:The runic seals? fades? away
msc += $boring:looks hungrier
msc += $boring:Something drops
msc += $boring:tears the web
msc += $boring:lashes its tail
msc += $boring:smirks and points a slender finger
msc += $boring:The orb of destruction dissipates
msc += $boring:spectral weapon stumbles backwards
msc += $boring:Your (claws|elbows|hands|wings) glow momentarily
msc += $boring:Weird images run through your mind
msc += $boring:safely over a trap
msc += $boring:avoid triggering a
msc += $boring:A net swings high above you
msc += $boring:Natasha extends her claws
msc += $boring:The shadow imp breathes steam at you
msc += $boring:You can't see any susceptible monsters within range
msc += $boring:You are momentarily dazzled by a brilliant light
msc += $boring:You feel momentarily weightless
msc += $boring:You feel uncomfortably cold
msc += $boring:Your fire elemental sizzles in the rain
msc += $boring:Nessos pounds the earth with his hooves
msc += $boring:Frost spreads across the the floor
msc += $boring:You sense an ancient evil watching you
msc += $boring:Your.*(looks|smiles) at you
msc += $boring:You experience a momentary feeling of inescapable doom
msc += $boring:Something in your inventory has become rotten
msc += $boring:There is something rotten in your inventory
msc += $boring:assumes a wrestling stance
msc += $boring:feints to the
msc += $boring:Purgy looks around nervously
msc += $boring:You smell pepper
msc += $boring:You feel faint for a moment
msc += $boring:You suddenly feel all small and vulnerable
msc += $boring:takes off
msc += $boring:There is a rock-blocked tunnel here
msc += $boring:falls off the
msc += $boring:The bat flutters around in erratic circles
msc += $boring:You swing at nothing
msc += $boring:This raw flesh tastes delicious
msc += $boring:electric golem crackles and sizzles
msc += $boring:ghost ripples
msc += $boring:Maud (frowns|looks upset)
msc += $boring:There is an ice choked empty arch of ancient stone here
msc += $boring:Sparks fly from your
msc += $boring:crimson imp breathes smoke at you
msc += $boring:Distant voices call out to you
msc += $boring:You are showered with tiny particles of grit
msc += $boring:The scroll reassembles itself in your
msc += $boring:You feel uncomfortably hot
msc += $boring:Nergalle blows her nose
msc += $boring:You release your grip on
msc += $boring:Nergalle looks more energetic
msc += $boring:stampedes away
msc += $boring:fails to trigger a.*trap
msc += $boring:You can't eat that
msc += $boring:You smell sulphur
msc += $boring:There's nothing to (close|open) nearby
msc += $boring:Your.*stumbles backwards
msc += $boring:ghost takes a fighting stance
msc += $boring:You shiver with fear
msc += $boring:Your.*falls like a stone
msc += $boring:You feel a surge of energy from the ground
msc += $boring:You release your grip on
msc += $boring:Your head hurts
msc += $boring:The lightning grounds out
msc += $boring:Your.*feel warm
msc += $boring:This isn't a weapon
msc += $boring:You feel as though nothing has changed
msc += $boring:Blork the orc's eyes start to glow
msc += $boring:Blork the orc shakes
msc += $boring:You smell wet wool
msc += $boring:You create a blast of rain
msc += $boring:There is a rose-covered archway here
msc += $boring:becomes larger for a moment
msc += $boring:falls out of your pack
msc += $boring:leaps into the air
msc += $boring:body glows momentarily
msc += $boring:shimmers violently
msc += $boring:makes a popping sound
msc ^= $boring:eyestalks stretch out
msc += $boring:You feel off-balance for a moment
msc ^= $boring:consumed by the void

# Enemies taking damage
msc += $good:You (batter|beat|bite|bludgeon|burn|carve|chomp|chop|claw|constrict|crush|cut|devastate|dice|drain|electrocute|eviscerate)
msc += $good:You (flatten|fracture|freeze|grab|gouge|hammer|headbutt|hit|impale|kick|mangle|maul|nip|open|peck|perforate|pierce|pound)
msc += $good:You (pulverise|pummel|punch|puncture|punish|scratch|sears|shatter|shave|shred|skewer|slash|slice|smack|sock)
msc += $good:You (spit|splatter|squash|squeeze|stick|strike|tail-slap|tentacle-slap|thrash|thump|touch|trample|whack)
msc += $good:(attacks|bites|burns|carves|chops|claws|constricts|crushes|cuts|drains|draws|electrocutes|engulfs) [^y]
msc += $good:(eviscerates|freezes|gores|grabs|headbutts|hits|hits|kicks|mauls|melts|opens|pecks|perforates) [^y]
msc += $good:(poisons|pulverises|pummels|punches|punctures|sears|shocks|shreds|skewers|slashes|slices|smacks) [^y]
msc += $good:(spits|squashes|sticks|stings|strikes|tail-slaps|tentacle-slaps|touches|tramples|trunk-slaps) [^y]
msc += $good:(twists|pulls at|violently warps) [^y]
msc += $good:You smite
msc ^= $good:Your fire elemental burns
msc += $good:is flooded with distortional energies
msc += $good:is electrocuted
msc += $good:You draw life from
msc += $good:is struck by the twisting air
msc += $good:burns!
msc += $good:Asterion shares his spectral weapon's damage
msc += $good:is struck by lightning
msc += $good:A guardian golem appears
msc += $good:is covered in liquid flames
msc += $good:is engulfed in
msc += $good:Your.*tramples the
msc += $good:The orb of electricity engulfs the
msc += $good:The (.*hellfire|blast of flame|blast of lightning|blast of magma|explosion) engulfs [^y]
msc += $good:The (explosion of.*fragments|explosion of spores|fiery explosion|fireball|ghostly fireball) engulfs [^y]
msc += $good:The (great blast of fire|plume of ash|stinking cloud) engulfs [^y]
msc += $good:is smitten
msc += $good:struck by your spines
msc += $good:There is a sudden explosion of sparks
msc += $good:is drained
msc += $good:You drain (her|his|its) (magic|power)
msc += $good:You drain the
msc += $good:Something (bites|hits)
msc += $good:is blasted
msc += $good:is burned by your radiant heat
msc += $good:The boulder beetle smashes into the
msc += $good:The golden flame engulfs
msc += $good:The eldritch tentacle writhes
msc ^= $good:The.*pierces through the
msc += $good:Space (bends|warps horribly) around
msc += $good:(convulses|writhes in agony)
msc += $good:is splashed with acid
msc += $good:You feel life coursing into your body
msc += $good:is struck by lightning
msc += $good:is burned by acid
msc += $good:seems to burn from within
msc += $good:Space warps around
msc ^= $good:statue shatters
msc += $good:Your eldritch tentacle slaps
msc += $good:collides with
msc += $good:slams into the

# Non-damage combat messages
msc += $positive:the.*corpse armour sloughs away
msc += $positive:You grow two more
msc += $positive:You draw.*blood
msc += $positive:You feel.*less thirsty
msc += $positive:You feel a lot less hungry
msc += $positive:You.*devour 
msc += $positive:You pounce on
msc += $positive:but is stunned by your will
msc += $positive:Your rust devil corrodes
msc += $positive:by your wave of power
msc += $positive:is stunned by your will and fails to attack
msc += $positive:The sticky flame splashes onto
msc ^= $positive:Your orcs go into a battle-frenzy
msc += $positive:falters in the face of your power
msc += $positive:in retribution by your aura
msc += $positive:Your slowness suddenly goes away
msc ^= $positive:Your.*seems less confused
msc += $positive:is no longer regenerating
msc += $positive:You repair your equipment
msc += $positive:You extend your infusion
msc += $positive:You draw the Helm
msc += $positive:You draw Dowsing
msc += $positive:You shrug off the repeated paralysis
msc ^= $positive:You begin infusing your attacks with magical energy
msc += $positive:It gets dark
msc += $positive:is outlined in light
msc += $positive:A mana viper appears with a sibilant hiss
msc += $positive:moth of wrath (goads|infuriates) your
msc += $positive:Some water evaporates in the bright sunlight
msc += $positive:You become one with your weapon
msc += $positive:Your bond becomes stronger
msc += $positive:A magical shield forms in front of you
msc += $positive:Your attacks no longer feel as feeble
msc += $positive:You feel odd
msc += $positive:The shadowy forms in the deep grow still as others approach
msc += $positive:You renew your portal
msc += $positive:You begin teleporting projectiles to their destination
msc += $positive:is no longer invulnerable
msc += $positive:blocks its attack
msc += $positive:sizzles in the rain
msc += $positive:gets badly buffeted
msc += $positive:Your legs become a tail as you enter the water
msc += $positive:You feel a sudden desire to slay dragons
msc += $positive:You feel weakened for a moment
msc += $positive:Your stone body feels more resilient
msc += $positive:You feel less vulnerable to hostile enchantments
msc += $positive:You swoop lightly up into the air
msc += $positive:You feel very comfortable in the air
msc += $positive:The air around you leaps into flame
msc += $positive:is knocked back by the great wave of water
msc += $positive:Your.*wounds heal themselves
msc += $positive:is recalled
msc += $positive:You renew your shroud
msc += $positive:One of your tentacles grows a vicious spike
msc += $positive:A mana viper appears with a sibilant hiss
msc += $positive:melts!
msc += $positive:You extend your mandibles
msc ^= $positive:Your?.*appears? unharmed
msc += $positive:You finish merging with the rock
msc += $positive:You gain the combat prowess of a mighty hero
msc += $positive:shroud falls apart
msc += $positive:Your.*glows blue
msc += $positive:your mind becomes perfectly clear
msc += $positive:You create a blast of noxious fumes!
msc += $positive:Roots rise up to grasp you
msc += $positive:is no longer moving.*quickly
msc += $positive:You create a snake
msc += $positive:apparition takes form in the air
msc += $positive:The rubble rises up and takes form
msc += $positive:You begin to abjure the creatures around you
msc += $positive:You extend your aura of abjuration
msc += $positive:A divine shield forms around you
msc += $positive:Your attacks no longer feel as feeble
msc += $positive:Your shroud bends.*attack away
msc += $positive:illusion disappears in a puff of smoke
msc += $positive:A beastly little devil appears in a puff
msc += $positive:Your.*is no longer encased in ice
msc += $positive:You deflect
msc += $positive:The lightning arcs
msc += $positive:is knocked back by the lance of force
msc += $positive:is dazzled
msc += $positive:is doused terribly
msc += $positive:An electric hum fills the air
msc += $positive:You summon a servant imbued with your destructive magic
msc += $positive:You are suffused with power
msc += $positive:The sheep.*panic
msc += $positive:The sheep turns to a blind rush
msc += $positive:Smoke pours from your nose
msc += $positive:The trap is out of ammunition
msc += $positive:You dart out from under the net
msc += $positive:The manticore spikes snap loose
msc += $positive:Your jumping spider.*pounces on the
msc += $positive:You are unaffected
msc += $positive:no longer looks unusually strong
msc += $positive:The area is filled with flickering shadows
msc += $positive:You block
msc += $positive:flinches away
msc += $positive:The.*is (deflected|repelled)
msc += $positive:Your.*is no longer paralysed.
msc += $positive:Your.*seems less confused
msc += $positive:You feel less contaminated with magical energies
msc += $positive:Your.*breaks free
msc += $positive:You feel momentarily confused
msc += $positive:That potion was really gluggy
msc += $positive:You resist
msc += $positive:You (easily|partially) resist
msc += $positive:Your skin crawls
msc += $positive:You draw out your weapon's spirit
msc += $positive:You catch the
msc += $positive:fails to defend (herself|himself|itself)
msc += $positive:falters for a moment
msc += $positive:You feel invigorated
msc += $positive:flops around on dry land
msc += $positive:You escape
msc += $positive:glows a violent red
msc += $positive:You emit a cloud
msc += $positive:icy envelope dissipates
msc += $positive:appears confused
msc += $positive:looks drowsy
msc += $positive:is caught in a (net|web)
msc += $positive:struggles to get unstuck from the (net|web)
msc += $positive:loses its grip on you
msc += $positive:looks rather.*confused
msc ^= $positive:The sentinel's mark upon you fades away
msc += $positive:The lost soul (fades away|flickers out)
msc += $positive:You turn into a creature of crystalline ice
msc ^= $positive:The.*dark mirror aura disappears
msc += $positive:is no longer berserk
msc += $positive:You wake up
msc += $positive:The grasping roots settle back into the ground
msc += $positive:The forest abruptly stops moving
msc += $positive:You feel more buoyant
msc += $positive:You fly up into the air
msc += $positive:You gasp with relief as air once again reaches your lungs
msc += $positive:A film of ice covers your body
msc += $positive:Your.*has recharged
msc += $positive:you pull free of the water engulfing you
msc += $positive:You feel a surge of unholy energy
msc += $positive:your?.*stops? burning
msc += $positive:begins to rapidly decay
msc += $positive:Your possessions no longer seem quite so burdensome
msc += $positive:You feel in control
msc += $positive:You feel odd for a moment
msc += $positive:suddenly stops moving
msc += $positive:is poisoned
msc += $positive:looks even sicker
msc += $positive:A film of ice covers your body
msc += $positive:is stunned!
msc += $positive:is flash-frozen
msc += $positive:seems to slow down
msc += $positive:is moving more slowly
msc += $positive:stops moving altogether
msc += $positive:Your skin hardens
msc += $positive:Your new body merges with your stone armour
msc += $positive:gives you a mild electric shock
msc += $positive:Eating
msc += $positive:the sound returns
msc += $positive:Your amulet of stasis gives you a mild electric shock
msc += $positive:You finish eating
msc += $positive:Your icy armour thickens
msc += $positive:The naga ritualist's toxic aura wanes
msc += $positive:Your.*pulls away from the web
msc += $positive:A chill wind blows around you
msc += $positive:You become transparent for a moment
msc += $positive:is charmed
msc += $positive:Your skin feels harder
msc += $positive:Shadowy shapes form in the air around you
msc += $positive:is burned terribly
msc += $positive:[^y].*is frozen
msc += $positive:You furiously retaliate
msc += $positive:The scroll dissolves into smoke
msc ^= $positive:Your.*reflects
msc ^= $positive:You reflect
msc += $positive:is no longer unusually agile
msc += $positive:struggles to blink free from constriction
msc += $positive:You pull the items towards yourself
msc += $positive:the former slaves? thanks? you
msc += $positive:Something gets caught in the net
msc += $positive:[^y].*rots
msc += $positive:the hog turns into a human
msc += $positive:the hogs revert to their human forms
msc += $positive:Your new body merges with your icy armour
msc += $positive:You feel the strange sensation of being on two planes at once
msc += $positive:A flood of magical energy pours into your mind
msc += $positive:You feel the material plane grow further away
msc += $positive:You momentarily phase out as.*passes through you
msc += $positive:You feel less exhausted
msc ^= $positive:Your.*(resist[^a]|resists|unaffected)
msc += $positive:The flame cauterises the wound
msc += $positive:the.*last head off
msc += $positive:You carefully extract the manticore spikes from your body
msc += $positive:You melt the
msc += $positive:has finally been put to rest
msc += $positive:begins to bleed from.*wounds
msc += $positive:Your.*draws strength from
msc += $positive:You feel yourself moving faster
msc += $positive:looks sick
msc += $positive:Your feet morph into talons
msc += $positive:You grow a pair of large bovine horns
msc += $positive:You extend your transformation
msc += $positive:Your.*turns? into razor-sharp scythe blades?
msc += $positive:You conjure a globe of magical energy
msc += $positive:You imbue your battlesphere with additional charge
msc += $positive:You feel resistant
msc += $positive:You are no longer poisoned
msc += $positive:looks frightened
msc += $positive:The.*is outlined in light
msc += $positive:You feel quick
msc += $positive:You no longer feel sluggish
msc += $positive:You feel odd for a moment
msc += $positive:returns to your pack
msc += $positive:Space distorts slightly along a thin shroud covering your body
msc += $positive:You are covered in a thin layer of ice
msc += $positive:You feel (clumsy|dopey|weak) for a moment
msc += $positive:stops singing
msc += $positive:and things crawl out
msc += $positive:You feel more catlike
msc += $positive:A crackling disc of dense vapour forms in the air
msc += $positive:icy armour evaporates
msc += $positive:Your.*looks invigorated
msc += $positive:repels the curse
msc += $positive:Yoink! You pull the item towards yourself
msc += $positive:but delicious nonetheless
msc += $positive:The disc of vapour around you crackles
msc += $positive:turns into a zombie
msc += $positive:You summon
msc += $positive:hydra's last head off
msc += $positive:You feel a.*surge of power
msc += $positive:magic leaks into the air
msc += $positive:You focus on the pain
msc += $positive:Your.*darts out from under the net
msc += $positive:struggles to escape constriction
msc += $positive:submits to your will
msc += $positive:You channel some magical energy
msc += $positive:is caught in the net
msc += $positive:struggles (against|to escape) the net
msc += $positive:Your fit of retching subsides
msc += $positive:Your magic seems less tainted
msc += $positive:You finish butchering
msc += $positive:You shudder from the blast and a jelly pops out
msc += $positive:looks weaker
msc += $positive:falls into the water
msc += $positive:You fade into the shadows
msc += $positive:life force is offered up
msc += $positive:is calmed by your holy aura
msc ^= $positive:You fade into invisibility
msc ^= $positive:grand avatar fades into the ether
msc ^= $positive:Your attacks are magically infused
msc ^= $positive:You feel protected from missiles
msc ^= $positive:You feel a little less hungry
msc ^= $positive:Your.*is no longer moving slowly
msc ^= $positive:You are no longer (entranced|glowing)
msc ^= $positive:You feel as if something is helping you
msc += $positive:appears in a shower of sparks
msc += $positive:Malign forces permeate your being
msc += $positive:A glowing mist starts to gather
msc ^= $positive:begin to glow red
msc ^= $positive:begin to glow brighter

#msc += $verypositive:
msc += $verypositive:You are bolstered by the flame
msc ^= $verypositive:The.*zombie.*rots away
msc += $verypositive:You feel buoyant
msc ^= $verypositive:You feel very safe from missiles
msc ^= $verypositive:You are no longer firmly anchored in space
msc += $verypositive:Magical energy flows into your mind!
msc ^= $verypositive:The terrible wounds on your body vanish
--amulet of stasis
msc += $verypositive:Your.*rumbles
msc += $verypositive:You feel life flooding into your body
msc += $verypositive:You feel purified
msc += $verypositive:You feel more resilient
msc += $verypositive:You get a glimpse of the first card
msc += $verypositive:You turn into a swirling mass of dark shadows
msc += $verypositive:You feel nimbler
msc += $verypositive:the tentacle is hauled back through the portal
msc += $verypositive:You feel more in control of your magic
msc += $verypositive:releases its grip on you
msc += $verypositive:You feel magically charged
msc += $verypositive:You turn to flesh and can move again
msc += $verypositive:Your magma supply has returned
msc += mute:HP restored
msc += mute:Magic restored
msc += $verypositive:You (blow up|destroy|kill)
msc += $verypositive:is blown up
msc += $verypositive:dies
msc += $verypositive:is destroyed
msc += $verypositive:is killed
msc += $verypositive:is incinerated
msc += $verypositive:is devoured by a tear in reality
msc += $verypositive:turns neutral
msc += $verypositive:The spatial vortex dissipates
msc += $verypositive:Your magical contamination has.*faded
msc += $verypositive:drowns
msc += $verypositive:The.*falls from the air
msc += $verypositive:The.*simulacrum vapourises
msc += $verypositive:more experienced
msc ^= $verypositive:rots away and dies
msc ^= $verypositive:You.*and break free
msc += $verypositive:The web tears apart
msc += $verypositive:You disentangle yourself
msc += $verypositive:Saving game... please wait
msc += $verypositive:You finish memorising
msc += $verypositive:You may choose your destination
msc += $verypositive:You feel yourself speed up
msc += $verypositive:You feel stealthy
msc += $verypositive:You feel less vulnerable to poison
msc += $verypositive:Your skill with magical items lets you calculate the power of this device
msc += $verypositive:You can move again
msc += $verypositive:The fungal colony is destroyed
msc ^= $verypositive:The starcursed mass shudders and is absorbed by its neighbour
msc ^= $verypositive:The starcursed mass shudders and withdraws
msc += $verypositive:You are no longer firmly anchored in space
msc += $verypositive:Magic courses through your body
msc += $verypositive:You have disarmed the trap
msc += $verypositive:You are healed
msc += $verypositive:Pain shudders through your arm
msc += $verypositive:You slip out of the net
msc += $verypositive:You break free from the net
msc += $verypositive:Your life force is being protected
msc += $verypositive:It is a scroll of recharging
msc += $verypositive:is converted
msc += $verypositive:It is a scroll of enchant
msc += $verypositive:That put a bit of spring back into your step
msc += $verypositive:You feel vaguely more buoyant than before
msc += $verypositive:You feel (better|faster|mighty|much better|protected|refreshed)
msc += $verypositive:You feel.* mighty all of a sudden
msc += $verypositive:You feel.*agile all of a sudden
msc += $verypositive:You feel aware of your surroundings
msc += $verypositive:You detect (creatures|items)
msc += $verypositive:You feel the corruption within you wane
msc += $verypositive:You feel perceptive
msc ^= $verypositive:You feel less confused
msc += $verypositive:You feel a little better
msc += $verypositive:You feel studious about
msc += $verypositive:You feel telepathic
msc += $verypositive:You feel your magic capacity increase
msc += $verypositive:You feel the abyssal rune guiding you out of this place
msc += $verypositive:You feel fantastic
msc += $verypositive:Found.*altar
msc += $verypositive:Found a one-way gate to the infinite horrors of the Abyss
msc += $verypositive:Found a glowing drain
msc += $verypositive:Found a gate leading back out of here
msc += $verypositive:Found a hole to the Spider Nest
msc += $verypositive:Found a frozen archway
msc += $verypositive:Found an ice covered gate leading
msc += $verypositive:Found a dark tunnel
msc += $verypositive:Found a labyrinth entrance
msc += $verypositive:Found a flagged portal
msc += $verypositive:Found an exit through the horrors of the Abyss
msc += $verypositive:Found a gateway leading out of the Abyss
msc += $verypositive:Found a gateway leading deeper into the Abyss
msc += $verypositive:Found a gate leading out of Pandemonium
msc += $verypositive:Found a gate leading to another region
msc += $verypositive:Found a gate to the Vaults
msc += $verypositive:Found a gateway
msc += $verypositive:Found a rocky tunnel leading out of this place
msc += $verypositive:Found a portal to a secret trove of treasure
msc += $verypositive:Found a magical portal
msc += $verypositive:Found a flickering gateway to a bazaar
msc += $verypositive:Found a one-way gate leading to the halls of Pandemonium
msc += $verypositive:Found a portal leading out of here
msc += $verypositive:Found.*staircase
msc += $verypositive:Found.*(Accessories|Antiques|Boutique|Distillery|Elixirs|Emporium|shop|Smithy|store)
msc += $verypositive:You feel your magical essence form a protective shroud around your flesh
msc += $verypositive:You feel your.*returning
msc += $verypositive:It is a scroll of brand weapon
msc ^= $verypositive:Your.*seems to speed up
msc += $verypositive:An interdimensional caravan has stopped on this level and set up a bazaar
msc += $verypositive:Your demonic ancestry asserts itself
msc += $verypositive:You feel (agile|clever|stronger)
msc += $verypositive:You feel more protected from negative energy

#Gaining positive mutations, or losing bad ones
msc += $awesome:You feel more jittery
msc += $awesome:You.*contain your magic power
msc += $awesome:Acid begins to drip from your mouth
msc += $awesome:You feel more resistant to cold
msc += $awesome:You feel less vulnerable to cold
msc += $awesome:Your fur grows into a thick mane
msc += $awesome:Your magic regains its normal vibrancy
msc += $awesome:Your thick fur grows shaggy and warm
msc += $awesome:You feel more sure on your
msc += $awesome:You feel breathless
msc += $awesome:Your genes go into a fast flux
msc += $awesome:You feel more resistant to heat
msc += $awesome:A poisonous barb forms on the end of your tail
msc += $awesome:Your wings grow larger and stronger
msc += $awesome:You feel more spiritual
msc ^= $awesome:You feel immune to rotting
msc += $awesome:Your system.*accepts artificial healing
msc += $awesome:You feel more resistant to hostile enchantments
msc += $awesome:You feel completely energised by your suffering
msc += $awesome:An ominous black mark forms on your body
msc += $awesome:You feel a strange anaesthesia
msc ^= $awesome:You feel resistant to heat
msc += $awesome:You feel saturated with power
msc += $awesome:You feel power rushing into your body
msc += $awesome:Your blood runs red-hot
msc += $awesome:Your feet have mutated into hooves
msc ^= $awesome:You feel resistant to hostile enchantments
msc += $awesome:You feel genetically immutable
msc += $awesome:You feel power flowing into your body
msc ^= $awesome:You feel more in touch with the powers of death
msc ^= $awesome:You feel resistant to poisons?
msc ^= $awesome:You feel resistant to (cold|fire)
msc ^= $awesome:You feel very resistant to (cold|fire)
msc += $awesome:You no longer feel vulnerable to (cold|fire)
msc += $awesome:Your urge to (scream|yell) lessens
msc += $awesome:One of your lower tentacles grows a sharp spike
msc += $awesome:You regain control of your magic
msc += $awesome:The horns on your head grow some more
msc += $awesome:You feel less concerned about heat
msc += $awesome:You smell fire and brimstone
msc += $awesome:You begin to radiate miasma
msc += $awesome:You feel able to eat a more balanced diet
msc += $awesome:You feel genetically stable
msc ^= $awesome:You feel a.*healthier
msc += $awesome:You hunger for flesh
msc += $awesome:You feel your life force and your magical essence meld
msc ^= $awesome:You feel your magical essence form a protective shroud around your flesh
msc += $awesome:You feel your magic shroud grow more resilient
msc += $awesome:Your body becomes stretchy
msc += $awesome:Your skin becomes partially translucent
msc += $awesome:You feel less concerned about cold
msc += $awesome:You feel cleansed
msc += $awesome:You are surrounded by darkness
msc += $awesome:Your skin functions as natural camouflage
msc += $awesome:You begin to emit a foul stench of rot and decay
msc += $awesome:You hunger for rotting flesh
msc ^= $awesome:You feel energised by your suffering
msc ^= $awesome:You feel even more energised by your suffering
msc += $awesome:Your teeth lengthen and sharpen
msc += $awesome:Your natural healing is strengthened
msc += $awesome:Eyeballs grow over part of your body
msc += $awesome:pseudopods.*grow
msc += $awesome:Your body.*splits into a small jelly
msc += $awesome:You begin to regenerate
msc += $awesome:You begin to radiate repulsive energy
msc += $awesome:Your repulsive radiation grows stronger
msc += $awesome:Your body's shape seems more normal
msc += $awesome:You feel the presence of a demonic guardian
msc += $awesome:Your guardian grows in power
msc += $awesome:Your scales feel tougher
msc += $awesome:Your teeth are very long and razor-sharp
msc += $awesome:You feel negative
msc += $awesome:You begin to heal more quickly
msc += $awesome:You feel healthy
msc += $awesome:You feel a little more calm
msc += $awesome:You feel nature experimenting on you
msc += $awesome:You feel a strange attunement to the structure of the dungeons
msc += $awesome:Your mouth lengthens and hardens into a beak
msc += $awesome:Fur sprouts all over your body
msc += $awesome:Your attunement to dungeon structure grows
msc += $awesome:You slip into the darkness of the dungeon
msc += $awesome:You slip further into the darkness
msc += $awesome:Your thoughts seem clearer
msc += $awesome:A wave of death washes over you
msc += $awesome:The wave of death grows in power
msc += $awesome:Sharp spines emerge from
msc += $awesome:Your vision sharpens
msc ^= $awesome:Your urge to shout disappears
msc ^= $awesome:scales grow over part of your
msc ^= $awesome:scales spread over more of your
msc += $awesome:scales cover you.*completely
msc += $awesome:You are partially covered in thin metallic scales
msc ^= $awesome:Something appears at your feet
msc ^= $awesome:Something appears before you
msc += $awesome:Your metabolism slows
msc += $awesome:Your bones become.*less dense
msc += $awesome:You feel (more robust|robust|very robust)
msc += $awesome:You feel more energetic
msc += $awesome:You feel healthier
msc += $awesome:You feel insulated
msc += $awesome:Your (fingernails|toenails) (lengthen|sharpen)
msc += $awesome:Your hands twist into claws
msc += $awesome:Your feet stretch into talons
msc += $awesome:Your feet thicken and deform
msc ^= $awesome:A pair of antennae grows on your head
msc ^= $awesome:The antennae on your head grow some more
msc ^= $awesome:There is a nasty taste in your mouth for a moment
msc ^= $awesome:You feel stable
msc += $awesome:Large bone plates (cover|grow|spread)
msc += $awesome:Your throat feels hot
msc += $awesome:Your teeth grow very long and razor-sharp
msc ^= $awesome:You feel less vulnerable to heat
msc ^= $awesome:You no longer feel vulnerable to heat
msc ^= $awesome:You feel a little less angry
msc += $awesome:Your natural camouflage becomes more effective

# Other rare and awesome stuff
msc ^= $awesome:seems mollified
msc += $awesome:Your surroundings flicker for a moment
msc += $awesome:You feel magically purged
msc += $awesome:word of recall is interrupted
msc ^= $awesome:Sif Muna is protecting you from the effects of miscast magic
msc ^= $awesome:You are shrouded in an aura of darkness
msc ^= $awesome:Kikubaaqudgha is protecting you from necromantic miscasts and death curses
msc += $awesome:You are surrounded by a storm
msc += $awesome:You sense an aura of extreme power
msc += $awesome:Your.*shines brightly
msc ^= $awesome:The Shining One will now bless your weapon at an altar
msc += $awesome:the more Ashenzari supports your skills
msc += $awesome:Ashenzari helps you to reconsider your skills
msc ^= $awesome:You and your allies can gain power from killing the unholy and evil
msc ^= $awesome:A divine halo surrounds you
msc ^= $awesome:You feel resistant to extremes of temperature
msc += $awesome:There is a labyrinth entrance here
msc += $awesome:There is an exit through the horrors of the Abyss here
msc += $awesome:You adapt resistances upon receiving elemental damage
msc += $awesome:The storm surrounding you grows powerful enough to repel missiles
msc += $awesome:There is a magical portal here
msc ^= $awesome:There is a gateway to a ziggurat here
msc ^= $awesome:Fruit sprouts up around you
msc ^= $awesome:A sheep catches fire
msc += $awesome:plants?.*grows? in the rain
msc += $awesome:You are restored by drawing out deep reserves of power within
msc ^= $awesome:Beogh aids your use of armour
msc ^= $awesome:Vehumet is extending the range of your destructive magics
msc += $awesome:You feel controlled for a moment
msc ^= $awesome:There is a gate to the Realm of Zot here
msc += $awesome:A monocle briefly appears
msc += $awesome:You feel an empty sense of dread
msc += $awesome:That felt like a moral victory
msc += $awesome:A shaft materialises beneath you
msc += $awesome:You draw Experience
msc += $awesome:You draw the Mercenary
msc += $awesome:Your body is suffused with negative energy
msc ^= $awesome:Qazlal will now grant you protection from an element of your choosing
msc ^= $awesome:Kikubaaqudgha is protecting mute from unholy torment
msc ^= $awesome:Kikubaaqudgha will now enhance your necromancy at an altar
msc += $awesome:You rejoin the land of the living
msc += $awesome:The sixfirhy explodes in a shower of sparks
msc += $awesome:With a swish of your cloak
msc += $awesome:Some fountains start gushing blood
msc += $awesome:A genie takes form and thunders\: \"Choose your reward
msc += $awesome:You turn into a fearsome dragon
msc += $awesome:You turn into a living statue of rough stone
msc += $awesome:You manage to scramble free
msc += $awesome:Your.*(rod|wand).*glows for a moment
msc += $awesome:You sense traps nearby
msc += $awesome:You now sometimes bleed smoke when heavily injured by enemies
msc += $awesome:Your shadow now sometimes tangibly mimics your actions
msc += $awesome:You sense items nearby
msc += $awesome:Suddenly you stand beside yourself
msc += $awesome:You feel somewhat nimbler
msc += $awesome:A mystic portal forms
msc += $awesome:You may select the general direction of your translocation
msc += $awesome:It is briefly surrounded by shifting shadows
msc += $awesome:The deck has exactly five cards
msc += $awesome:You are no longer firmly anchored in space
msc += $awesome:There is a gate to the Realm of Zot here
msc += $awesome:A terribly searing pain shoots up your
msc += $awesome:Your strength has recovered
msc += $awesome:A flood of memories washes over you
msc ^= $awesome:Vehumet offers you knowledge of
msc ^= $awesome:With a loud hiss the gate opens wide
msc += $awesome:You have collected all the runes
msc += $awesome:a hidden mimic gets squished
msc += $awesome:Now go and win
msc += $awesome:You feel knowledgeable
msc += $awesome:The arc blade crackles to life
msc ^= $awesome:There is a gate leading out of Pandemonium here
msc += $awesome:You feel powerful
msc ^= $awesome:You can now
msc += $awesome:joins your ranks
msc += $awesome:Your magic begins regenerating once more
msc += $awesome:Your.*is now the
msc += $awesome:There is a glowing drain
msc ^= $awesome:There is a gateway leading out of the Abyss here
msc += $awesome:There is a sand-covered staircase here
msc += $awesome:Your.*crackles with electricity
msc ^= $awesome:This is a scroll of acquirement
msc += $awesome:You pick up the.*rune
msc += $awesome:You now have.*rune
msc += $awesome:Your.*skill increases
msc += $awesome:You have reached level
msc += $awesome:Your experience leads to an increase in your attributes
msc ^= $awesome:There is a frozen archway here
msc ^= $awesome:There is a dark tunnel here
msc ^= $awesome:There is a flagged portal here
msc ^= $awesome:There is a portal to a secret trove of treasure here
msc ^= $awesome:There is a flickering gateway to a bazaar here
msc ^= $awesome:There is an entrance to.*on this level
msc += $awesome:3 runes! That's enough to enter the realm of Zot
msc += $awesome:The lock glows eerily
msc += $awesome:Heavy smoke blows from the lock
msc += $awesome:You have escaped!
msc += $awesome:rune into the lock
msc += $awesome:With a loud hiss the gate opens wide
msc += $awesome:You sensed
msc += $awesome:You are wearing\:
msc += $awesome:With a loud hiss the gate opens wide
msc += $awesome:The shadows inhabiting this place fade forever
msc += $awesome:You have identified the last
msc += $awesome:You feel a craving for the dungeon's cuisine
msc ^= $awesome:Lugonu will now corrupt your weapon
msc ^= $awesome:You now have enough gold to petition Gozag for potion effects
msc ^= $awesome:You now have enough gold to fund merchants seeking to open stores in the dungeon

# Weapon brands/enchantment
msc ^= $awesome:A searing pain shoots up your
msc += $awesome:You hear the crackle of electricity
msc += $awesome:You see sparks fly
msc += $awesome:Your hands tingle
msc += $awesome:Your claws tingle
msc += $awesome:You feel a dreadful hunger
msc ^= $awesome:Your.*glows (green|purple|red|.*yellow)
msc += $awesome:briefly pass through it before

# You or an ally takes damage
msc ^= $negative:Your.*writhes in agony
msc += $negative:you trip and fall down the stairs
msc += $negative:You are engulfed in blessed fire
msc ^= $negative:collides with you
msc += $negative:The fountain mimic splashes you
msc += $negative:Your body is twisted very painfully
msc += $negative:crushes you
msc ^= $negative:drains your
msc += $negative:Your body is distorted in a weirdly horrible way
msc ^= $negative:Your.*is struck by the twisting air
msc += $negative:You are constricted
msc ^= $negative:Your.*is blasted
msc += $negative:Electricity courses through your body
msc ^= $negative:Your.*is struck by lightning
msc += $negative:You are struck by lightning
msc += $negative:silver sears your?
msc += $negative:You draw magical energy from your own body
msc += $negative:Rocks fall onto you out of nowhere
msc += $negative:You are engulfed in raging winds
msc ^= $negative:Your.*convulses
msc += $negative:You are struck by the briar patch's thorns
msc += $negative:You feel like your blood is boiling
msc += $negative:The magical storm engulfs you
msc += $negative:The acid blast engulfs you
msc += $negative:starcursed mass engulfs you
msc += $negative:The pyre of ghostly fire engulfs you
msc += $negative:Your body is flooded with distortional energies
msc += $negative:You are caught in a strong localised spatial distortion
msc ^= $negative:The Shining One blasts you with cleansing flame
msc += $negative:You are struck by lightning
msc += $negative:You are caught in an extremely strong localised spatial distortion
msc += $negative:You are blasted with searing flames
msc += $negative:Your.*suffers a backlash
msc ^= $negative:Your.*is smitten
msc += $negative:You are blasted with fire
msc ^= $negative:Your.*is engulfed in
msc ^= $negative:A huge blade swings out and slices into your?
msc += $negative:Flames sear your flesh
msc += $negative:A wave of violent energy washes through your body
msc += $negative:You are caught in a localised spatial distortion
msc ^= $negative:Heat is drained from your body
msc += $negative:Energy rips through your body
msc += $negative:You feel you are being watched by something
msc += $negative:Unholy energy fills the air
msc += $negative:You are caught in a localised field of spatial distortion
msc += $negative:The ghost moth stares at you
msc += $negative:Your ice beast melts
msc ^= $negative:burns you
msc ^= $negative:The poison in your system burns
msc += $negative:Your.*burn
msc += $negative:draws from the surrounding life force
msc += $negative:The boulder beetle smashes into you
msc += $negative:You feel very cold
msc ^= $negative:The.*pierces through (you|your)
msc ^= $negative:The walls? burns? you
msc ^= $negative:Your.*is blown up
msc += $negative:The throwing net hits your
msc += $negative:Your body is suffused with distortional energy
msc += $negative:constricts your?
msc += $negative:(bites|burns|claws|freezes|gores|gores|headbutts|hits|kicks|pecks|pecks|poisons|punches) your?
msc += $negative:(shocks|skewers|slaps|smites|stings|tail-slaps|tentacle-slaps|touches|tramples|trunk-slaps) your?
# Thanks killer klowns
msc += $negative:(kneecaps|defenestrates|elbows|flogs|headlocks|pinches|pokes|pounds|prods|squeezes|strangle-hugs|teases|tickles|trip-wires|wrestles) your?
msc += $negative:Your.*burned by acid
msc += $negative:Your?.*is struck by the.*spines
msc += $negative:Your spectral weapon shares its damage
msc += $negative:The.*begins to radiate
msc += $negative:The.*toxic radiance grows
msc += $negative:Your.*loses its grip
msc += $negative:The water swirls and strikes you
msc += $negative:Your.*is knocked back
msc += $negative:The shock serpent's electric aura discharges violently
msc += $negative:The lightning shocks
msc += $negative:The tentacled starspawn engulfs you
msc += $negative:The.*ugly thing engulfs you
msc ^= $negative:Your life force is offered up
msc ^= $negative:The (.*hellfire|blast of flame|blast of lightning|blast of magma|explosion) engulfs your?
msc ^= $negative:The (explosion of.*fragments|explosion of spores|fiery explosion|fireball|ghostly fireball) engulfs your?
msc ^= $negative:The (great blast of fire|plume of ash|stinking cloud|blast of energy) engulfs your?
msc += $negative:Pain shoots through your body
msc += $negative:Your.*is flash-frozen
msc += $negative:You writhe in agony
msc += $negative:you feel sick
msc += $negative:Something smites you
msc ^= $negative:The air twists around and.*strikes you
msc += $negative:You are hit by a branch
msc += $negative:You are caught in an explosion of flying shrapnel
msc += $negative:You are hit by flying rocks
msc += $negative:You slam into
msc += $negative:You collide with
msc ^= $negative:strikes at you from the darkness
msc += $negative:Your?.*burned terribly
msc += $negative:covered in liquid flames
msc += $negative:You are blasted with ice
msc += $negative:Your.*seems to slow down
msc += $negative:You are electrocuted
msc += $negative:and unravels at your touch
msc += $negative:You are struck by the.*spines
msc += $negative:The water rises up and strikes you
msc += $negative:The torrent of lightning arcs to you
msc += $negative:A root smacks your
msc += $negative:The eye of draining stares at you
msc += $negative:The (great icy blast|orb of electricity|noxious blast) engulfs you
msc += $negative:The barbed spikes dig painfully into your body as you move
msc += $negative:You are engulfed in (a cloud of scalding steam|flames|freezing|freezing vapours)
msc += $negative:You are engulfed in (ghostly flame|negative energy|noxious fumes|poison gas|roaring flames)
msc += $negative:A root smacks you from below
msc += $negative:Ka-crash
msc += $negative:You are frozen
msc ^= $negative:draws life force from you
msc += $negative:You have a terrible headache
msc += $negative:Your damage is reflected back at you
msc += $negative:Your body is twisted painfully
msc += $negative:Your scythe-like blades burn
msc ^= $negative:Your.*is (burned by|splashed with) acid
msc += $negative:Your.*is constricted
msc += $negative:The freed slave is burned by acid
msc += $negative:Something.*your
msc += $negative:snaps closed at you
msc += $negative:headbutts you!
msc += $negative:engulfs your
msc += $negative:You are blasted with magical energy
msc += $negative:The large rock crashes through you
msc += $negative:You are blasted!
msc += $negative:is hit by a branch
msc += $negative:The wandering mushroom releases spores at your?

#monster resists
msc += $danger:completely resists
msc += $warning:resists

# Text describing ranged attacks and spells
msc ^= $takesaction:chants a haunting song
msc += $takesaction:You release an incredible blast of power in all directions
msc += $takesaction:calls upon its god to speed up
msc += $takesaction:You create a blast
msc += $takesaction:The ophan calls forth blessed flames
msc += $takesaction:You exhale
msc += $takesaction:You enter the passage of Golubria
msc += $takesaction:You conjure a prism of explosive energy
msc += $takesaction:A raging storm of fire appears
msc += $takesaction:Sojobo summons a great blast of wind
msc += $takesaction:A fierce wind blows from the fan
msc ^= $takesaction:Rupert roars wildly at you
msc += $takesaction:A fierce wind blows
msc += $takesaction:The wizard shimmers violently
msc += $takesaction:releases spores
msc += $takesaction:The giant eyeball stares at you
msc += $takesaction:You begin recalling your allies
msc += $takesaction:You begin to radiate toxic energy
msc += $takesaction:The wretched star glows turbulently
msc += $takesaction:You begin to meditate on the wall
msc += $takesaction:You dig through the rock wall
msc += $takesaction:You ignite the poison in your surroundings
msc += $takesaction:You attempt to give life to the dead
msc ^= $takesaction:hurls a stone arrow
msc += $takesaction:weaves a glowing orb of energy
msc += $takesaction:spins a strand of pure energy
msc += $takesaction:Aizul coils himself and waves his upper body at you
msc ^= $takesaction:The royal jelly spits out
msc ^= $takesaction:calls upon Beogh to heal
msc ^= $takesaction:prays to Beogh
msc ^= $takesaction:calls down the wrath of
msc ^= $takesaction:invokes the aid of Beogh
msc += $takesaction:utters an invocation to Beogh
msc += $takesaction:shining eye gazes
msc += $takesaction:orb of fire glows
msc += $takesaction:orb of fire emits
msc += $takesaction:utters an invocation to its god
msc += $takesaction:offers its life energy for powerful magic
msc += $takesaction:utters a dark prayer and points at you
msc += $takesaction:waves its arms in wide circles
msc += $takesaction:is infused with unholy energy
msc += $takesaction:shambling mangrove reaches out with a gnarled limb
msc += $takesaction:You jump-attack
msc += $takesaction:The injured rakshasa weaves a defensive illusion
msc += $takesaction:Mara seems to draw the.*out of itself
msc += $takesaction:Mara shimmers
msc += $takesaction:Your battlesphere fires
msc += $takesaction:curse skull calls on the powers of darkness
msc += $takesaction:curse skull rattles its jaw
msc += $takesaction:Your shadow mimicks your spell
msc += $takesaction:calls down the wrath of its god upon you
msc += $takesaction:invokes the aid of its god against you
msc += $takesaction:rakshasa weaves an illusion
msc += $takesaction:coils itself and waves its upper body at you
msc += $takesaction:casts a spell
msc += $takesaction:You breathe a
msc ^= $takesaction:You draw life from your surroundings
msc += $takesaction:You step out of the flow of time
msc += $takesaction:You can feel time thicken for a moment
msc += $takesaction:The chunk of flesh you are holding crumbles to dust
msc += $takesaction:flesh is ripped from the corpse
msc += $takesaction:The flow of time bends around you
msc += $takesaction:You start singing a song of slaying
msc += $takesaction:The disc erupts in an explosion of electricity!
msc += $takesaction:and something leaps out
msc += $takesaction:You assume a fearsome visage
msc ^= $takesaction:Asterion utters an invocation to Makhleb
msc ^= $takesaction:Asterion conjures a destructive force in the name of Makhleb
msc ^= $takesaction:wizard howls an incantation
msc ^= $takesaction:draws from the surrounding life force
msc ^= $takesaction:Gastronok chants a spell
msc ^= $takesaction:(breathes|spits).*at
msc += $takesaction:You conjure a mighty blast of ice
msc += $takesaction:conjures a mighty blast of ice
msc ^= $takesaction:Your spellforged servitor (casts|conjures|launches)
msc += $takesaction:You reach into the bag
msc += $takesaction:You gaze into the crystal ball
msc += $takesaction:Your jumping spider leaps
msc ^= $takesaction:ice dragon breathes frost
msc ^= $takesaction:points at you and mumbles some strange words
msc += $takesaction:(fires|shoots|throws) [^n]
msc += $takesaction:You (fire|shoot|throw)
msc += $takesaction:You magically throw
msc += $takesaction:(conjures|fires|gestures|plays a|radiates)
msc ^= $takesaction:mumbles some strange (prayers|words)
msc ^= $takesaction:spriggan berserker (invokes|prays to|utters an invocation to) Trog
msc ^= $takesaction:calls down the wrath of the Shining One
msc += $takesaction:casts a spell.*floats close
msc += $takesaction:offers itself to Yredelemnul
msc ^= $takesaction:launches metal splinters at you
msc += $takesaction:(Angry insects surge|Agitated ravens fly) out from beneath the
msc ^= $takesaction:begins absorbing vital energies
msc ^= $takesaction:calls forth a grand avatar
msc ^= $takesaction:exhales a fierce blast of wind
msc ^= $takesaction:curls into a ball and starts rolling
msc ^= $takesaction:You open the lid...
msc ^= $takesaction:jumps down from its now dead mount
msc ^= $takesaction:swoops through the air toward you
msc ^= $takesaction:jumping spider pounces on
msc ^= $takesaction:jumping spider leaps
msc += $takesaction:manticore flicks its tail
msc += $takesaction:You begin to abjure the creatures around you
msc ^= $takesaction:The golden eye blinks at you
msc ^= $takesaction:Frances chants phrases taken from a Devil's mouth
msc ^= $takesaction:Frances screams a word of power
msc ^= $takesaction:Frances whispers indecipherable words
msc ^= $takesaction:Frances mutters in a terrible tongue
msc ^= $takesaction:activates a sealing rune
msc ^= $takesaction:offers up its power
msc += $takesaction:You warp the flow of time around you
msc += $takesaction:summons
msc += $takesaction:great orb of eyes gazes at
msc += $takesaction:You radiate an aura of cold
msc += $takesaction:Space collapses on itself with a satisfying crunch

# Gods performing actions
msc += $godaction:You reveal the great annihilating truth to your foes
msc ^= $godaction:Dithmenos does not appreciate your starting fires
msc += $godaction:Beogh throws an implement of electrocution at you
msc += $godaction:Beogh throws implements of electrocution at you
msc += $godaction:Beogh sends forth an army of orcs
msc += $godaction:you feel ready to understand
msc += $godaction:You feel a surge of divine interest
msc += $godaction:(Ashenzari|Beogh|Cheibriados|Dithmenos|Elyvilon|Fedhas|Gozag|Igni Ipthes|Jiyva|Kikubaaqudgha|Lugonu)
msc += $godaction:(Makhleb|Nemelex Xobeh|Okawaru|Qazlal|Sif Muna|The Shining One|Trog|Vehumet|Xom|Yredelemnul|Zin[^g])
msc ^= $godaction:(Ashenzari|Beogh|Cheibriados|Dithmenos|Elyvilon|Fedhas|Gozag|Igni Ipthes|Jiyva|Kikubaaqudgha|Lugonu) says
msc ^= $godaction:(Makhleb|Nemelex Xobeh|Okawaru|Qazlal|Sif Muna|The Shining One|Trog|Vehumet|Xom|Yredelemnul|Zin[^g]) says
msc ^= $godaction:Your divine halo returns
msc += $godaction:is distracted by the nearby gold
msc += $godaction:soul is now ripe for the taking
msc += $godaction:sets up shop in the Dungeon
msc ^= $godaction:You redirect
msc ^= $godaction:You feel protected from physical attacks
msc ^= $godaction:You feel protected from cold
msc ^= $godaction:You feel protected from fire
msc ^= $godaction:You feel protected from electricity
msc += $godaction:resistances upon receiving elemental damage
msc += $godaction:A storm cloud blasts the area with cutting wind
msc += $godaction:A blizzard blasts the area with ice
msc += $godaction:Magma suddenly erupts from the ground
msc ^= $godaction:Xom calls
msc += $godaction:The storm around you weakens
msc += $godaction:The ground shakes violently
msc += $godaction:The storm around you strengthens
msc += $godaction:due to Igni's heat
msc += $godaction:A mighty gale blasts forth
msc += $godaction:A fiery fortress appears around you!
msc += $godaction:is consumed in a column of flame
msc += $godaction:The toadstool can now pick up its mycelia and move
msc += $godaction:Slime for the Slime God
msc ^= $godaction:Cheibriados rebukes [^y]
msc ^= $godaction:You hear Xom
msc ^= $godaction:Go forth and redecorate
msc += $godaction:This is a.*sacrifice
msc ^= $godaction:Xom.*touches
msc ^= $godaction:You need some minor
msc ^= $godaction:Let me alter your
msc ^= $godaction:Xom complains about the scenery
msc ^= $godaction:Xom howls with laughter
msc ^= $godaction:This place needs a little more atmosphere
msc ^= $godaction:The area is suffused with divine lightning
msc ^= $godaction:Let's go for a ride
msc ^= $godaction:Xom momentarily opens a gate
msc ^= $godaction:Where it stops
msc ^= $godaction:\"First here\, now there\.\"
msc ^= $godaction:\"Over there now!\"
msc ^= $godaction:Serve the toy\, my child
msc ^= $godaction:Fight to survive\, mortal
msc ^= $godaction:Xom opens a gate
msc ^= $godaction:Xom slaps you with
msc ^= $godaction:You hear crickets chirping
msc ^= $godaction:Get over here
msc ^= $godaction:Go forth and destroy
msc ^= $godaction:Xom laughs nastily
msc ^= $godaction:Everything around seems to assume a strange transparency
msc ^= $godaction:You feel watched
msc ^= $godaction:The walls suddenly lose part of their structure
msc ^= $godaction:You are now a BORING thing
msc ^= $godaction:Xom makes a sudden noise
msc ^= $godaction:Xom roars with laughter
msc ^= $godaction:You feel someone pinching you\. As you turn\, you see no one
msc ^= $godaction:\"Try this\.\"
msc ^= $godaction:\"Whee!\"
msc ^= $godaction:\"Catch!\"
msc ^= $godaction:\"Here.\"
msc ^= $godaction:\"Boo!\"
msc ^= $godaction:\"Tag\, you\'re it!\"
msc ^= $godaction:\"Boring in life\, Boring in death\"
msc ^= $godaction:\"This might be better!\"
msc ^= $godaction:\"I like them better like this\.\"
msc ^= $godaction:\"Heh heh heh\.\.\.\"
msc ^= $godaction:\"Burn\, baby\, burn!\"
msc ^= $godaction:\"Time to have some fun!\"
msc ^= $godaction:\"Have a taste of chaos\, mortal\.\"
msc ^= $godaction:\"See what I see\, my child!\"
msc ^= $godaction:\"Just a minor improvement\.\.\.\"
msc ^= $godaction:\"Hum-dee-hum-dee-hum\.\.\.\"
msc ^= $godaction:\"There\, this looks better\.\"
msc ^= $godaction:\"You have grown too confident for your meagre worth\.\"
msc ^= $godaction:\"Take this token of my esteem\.\"
msc ^= $godaction:\"Take this instrument of something!\"
msc ^= $godaction:\"See what I see\, my child!\"
msc ^= $godaction:\"What!\? Thats's it\?!\"c
msc ^= $godaction:\"Serve the (mortal|toy)\, my (child|children)!\"
msc ^= $godaction:Let\'s see if it\'s strong enough to survive yet

# Interface Messages - These shouldn't take any turns
msc += $interface:You cannot read scrolls
msc += $interface:You cannot drink potions
msc += $interface:too exhausted to
msc += $interface:There are no objects that can be picked up here
msc += $interface:Calm down first
msc += $interface:You enter a permanent teleport trap
msc += $interface:too cloudy to do that here
msc += $interface:A powerful magic interferes with the creation of the passage
msc += $interface:You cannot apport that
msc += $interface:The film of ice won't work on stone
msc += $interface:You refuse to eat that rotten meat
msc += $interface:You see nothing there to enslave the soul of
msc += $interface:There isn't anything that you can close there
msc += $interface:Choose some type of armour to enchant
msc += $interface:You can't place the prism on a creature
msc += $interface:You are too depleted to cast spells recklessly
msc += $interface:It's stuck to you
msc += $interface:You're in a travel-excluded area
msc += $interface:You are unable to make a sound
msc += $interface:Choose an unidentified item
msc += $interface:There is nothing here that can be animated
msc += $interface:No.*are visible
msc += $interface:No evolvable flora in sight
msc += $interface:You must target a plant or fungus
msc += $interface:No target in range
msc += $interface:This is a.*deck
msc += $interface:No exploration algorithm can help you here
msc += $interface:You cannot walk through the dense trees
msc += $interface:This wall is too hard to dig through
msc += $interface:You can't dig through that
msc += $interface:You are already wielding that
msc += $interface:There isn't anything suitable to butcher here
msc ^= $interface:Something interferes with your magic
msc += $interface:You can only heal others!
msc += $interface:You are already wielding that
msc += $interface:You don't know.*spells?
msc += $interface:That is presently inert
msc += $interface:That isn't a deck
msc += $interface:Reset throwing quiver to default
msc += $interface:You can't memorise that many levels of magic yet
msc += $interface:You aren't wielding a weapon
msc += $interface:You'd need your.*free
msc += $interface:I'll put part of them outside for you
msc += $interface:You're in a travel-excluded area\, stopping explore
msc += $interface:There is a passage of Golubria here
msc += $interface:you can't auto-travel out of here
msc += $interface:waypoint
msc += $interface:You aren't in the Abyss
msc += $interface:You haven't found any runes yet
msc += $interface:This weapon is holy and will not allow you to wield it
msc += $interface:Huh\?
msc += $interface:You can't drink
msc += $interface:You cannot cast that spell in your current form
msc ^= $interface:is stuck to you
msc += $interface:is melded into your body
msc ^= $interface:Your.*feels? slithery
msc += $interface:You can't wear anything in your present form
msc += $interface:You're too inexperienced to learn that spell
msc += $interface:You're already wearing two cursed rings
msc += $interface:You need a rune to enter this place
msc ^= $interface:There is an ice covered gate leading back out of here here
msc += $interface:The bosom of this dungeon contains the most powerful artefact
msc += $interface:Clearing travel trail
msc += $interface:Your pack is full
msc += $interface:You can't pick everything up
msc += $interface:Could not pick up an item
msc += $interface:You can't carry that many items
msc += $interface:You enter the Abyss
msc += $interface:You enter the halls of Pandemonium
msc += $interface:This wand has
msc += $interface:That is beyond the maximum range
msc += $interface:You can't (drink|read) that
msc += $interface:You cannot shoot.*while held in a net
msc += $interface:You're already here
msc += $interface:You can't do that
msc += $interface:Cleared annotation
msc += $interface:Your cursed.*is stuck to you
msc += $interface:You have no means to grasp a wand firmly enough
msc += $interface:Choose a valid weapon
msc += $interface:No previous command
msc += $interface:You sense a monster
msc += $interface:Welcome
msc += $interface:There is a.*trap here
msc += $interface:There is a.*(entrance|staircase).*here
msc += $interface:That item cannot be evoked
msc += $interface:Please enjoy your stay
msc += $interface:You now have enough gold to buy
msc += $interface:Showing terrain only
msc += $interface:Returning to normal view
msc += $interface:Done exploring
msc += $interface:You pace your travel speed to your slowest ally
msc += $interface:The water rises up and takes form
msc += $interface:The winds coalesce and take form
msc += $interface:The.*answers the.*call
msc += $interface:You're too full
msc += $interface:Your memorisation is interrupted
msc += $interface:surroundings become eerily quiet
msc += $interface:You fall into the shallow water
msc += $interface:an escape hatch
msc += $interface:You stop dropping stuff
msc += $interface:melds into your body
msc += $interface:Clearing level map
msc += $interface:There's nothing close enough
msc += $interface:Autopickup is now
msc += $interface:Hurry and find it before the portal
msc += $interface:You slide downwards
msc += $interface:Can't find anything matching that
msc += $interface:No item to drop
msc += $interface:you feel a great hunger. Being not satiated
msc += $interface:You finish taking off
msc += $interface:appears from thin air
msc += $interface:You feel more attuned to
msc += $interface:(Attack!|Fall back!|Follow me!|Stop fighting!|Wait here!)
msc += $interface:You have finished your manual
msc += $interface:Expect minor deviation
msc += $interface:You have no appropriate body parts free
msc += $interface:Your cloak prevents you from wearing the armour
msc ^= $interface:You finish putting on
msc += $interface:You can't carry that much weight
msc += $interface:isn't holding a weapon that can be rebranded
msc += $interface:You feel the dreadful sensation subside
msc += $interface:You feel an oppressive heat about you
msc += $interface:You travel at normal speed
msc += $interface:Your reserves of magic are already full
msc += $interface:There are no corpses nearby
msc += $interface:No target in view
msc += $interface:It (is|was) a (potion|scroll)
msc += $interface:Aborting
msc += $interface:Created macro
msc += $interface:Saving macro
msc += $interface:you cannot use those schools of magic

# Muted - unnecessary
msc += mute:The (bush|fungus|plant) is engulfed
msc += mute:The (bush|fungus|plant) is struck by lightning
msc += mute:Cast which spell
msc += mute:Use which ability
msc += mute:Evoke which item
msc += mute:Confirm with
msc += mute:(Casting|Aiming|Zapping)\:
msc += mute:Throwing.*\:
msc += mute:You can\'t see any susceptible monsters within range
msc += mute:Press\: \? \- help, Shift\-Dir \- straight line, f \- you
msc += mute:for a list of commands and other information
msc += mute:Firing \(i
msc += mute:Fire\/throw which item\?
msc += mute:You swap places

msc ^= mute:is lightly (damaged|wounded)
msc ^= mute:is moderately (damaged|wounded)
msc ^= mute:is heavily (damaged|wounded)
msc ^= mute:is severely (damaged|wounded)
msc ^= mute:is almost (dead|destroyed)

msc += mute:Was it this warm in here before
msc += mute:The flames dance
msc += mute:Your shadow attacks
msc += mute:Marking area around
msc += mute:Placed new exclusion
msc += mute:Reduced exclusion size to a single square
msc += mute:Removed exclusion
msc += mute:You can access your shopping list by pressing
msc += mute:for starvation awaits
msc += mute:As you enter the labyrinth
msc += mute:previously moving walls settle noisily into place
msc += mute:You offer a prayer to Elyvilon
msc += mute:You offer a prayer to Nemelex Xobeh
msc += mute:You offer a prayer to Okawaru
msc += mute:You offer a prayer to Makhleb
msc ^= mute:You offer a prayer to Lugonu
msc += mute:Lugonu accepts your kill
msc += mute:Okawaru is noncommittal
msc += mute:Nemelex Xobeh is (noncommittal|pleased)
msc += mute:The plant looks sick
msc += mute:You start butchering
msc += mute:You continue butchering
msc += mute:This raw flesh tastes terrible

: if string.find(you.god(), "Jiyva") then
  msc += mute:You hear a.*slurping noise
  msc += mute:You hear a.*squelching noise
  msc += mute:You feel a little less hungry
: end

--These don't seem to work, maybe a bug?
msc ^= boring:disappears without a glow
msc ^= boring:disappears without a sign
msc ^= boring:disappears into the void
msc ^= boring:glow with a rainbow of weird colours and disappear
msc ^= boring:glows slightly and disappears
msc ^= boring:is slowly consumed by flames
msc ^= boring:slowly burns to ash
msc ^= boring:slowly crumbles into the ground
msc ^= boring:shimmers? and breaks? into pieces
msc ^= boring:stares at you suspiciously for a moment
msc += boring:trembles before you
msc += boring:You feel mildly nauseous
msc += boring:Multicoloured lights dance around
