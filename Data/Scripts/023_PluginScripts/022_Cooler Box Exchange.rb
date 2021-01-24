class CapturePokemonUI
  def initialize(pokemon)
    @sprites = {}
    @pokemon = pokemon
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites,"background","catchbg",@viewport)
    @sprites["base"] = IconSprite.new(256,256,@viewport)
    @sprites["base"].setBitmap("Graphics/Pictures/catchbase")
    @sprites["base"].ox = @sprites["base"].bitmap.width/2
    @sprites["base"].oy = @sprites["base"].bitmap.height/2
    @sprites["pkmn"] =  PokemonSprite.new(@viewport)
    @sprites["pkmn"].setOffset(PictureOrigin::Bottom)
    @sprites["pkmn"].setPokemonBitmap(@pokemon)
    @sprites["pkmn"].x = 256
    @sprites["pkmn"].y = 256
    fSpecies = pbGetFSpeciesFromForm(@pokemon.species,@pokemon.form)
    @sprites["pkmn"].y += (pbLoadSpeciesMetrics[MetricBattlerEnemyY][fSpecies] || 0) * 2
    pbFadeInAndShow(@sprites)
    ret = update
    dispose
    return ret
  end

  def dispose
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
  end

  def update
    if $Trainer.pokedex && !($Trainer.seen?(@pokemon.species) || $Trainer.owned?(@pokemon.species))
      $Trainer.seen[@pokemon.species]  = true
      $Trainer.owned[@pokemon.species] = true
      pbSeenForm(@pokemon)
      pbMessage(_INTL("{1}'s data was added to the Pokédex.",@pokemon.name))
      dexscene = PokemonPokedexInfo_Scene.new
      dexscreen = PokemonPokedexInfoScreen.new(dexscene)
      dexscreen.pbDexEntry(@pokemon.species)
    end
    if pbBoxesFull? && $Trainer.party.length == 6
      pbMessage(_INTL("There's no more room for Pokémon!\1"))
      return
    end
    pbNickname(@pokemon) if !@pokemon.shadowPokemon?
    @pokemon.pbRecordFirstMoves
    if $Trainer.party.length == 0
      pbAddToPartySilent(@pokemon)
      pbMessage(_INTL("{2} was added to {1}'s party!",$Trainer.name,@pokemon.name))
      return
    end
    cmd = -1
    loop do
      Graphics.update
      pbUpdateSpriteHash(@sprites)
      cmd = pbMessage("What would you like to do with #{@pokemon.name}?",["Keep in party","Send to storage","Check #{@pokemon.name}'s summary","Check Party Summary"]) {pbUpdateSpriteHash(@sprites)}
      case cmd
      when 0
        if $Trainer.party.length < 6
          pbAddToPartySilent(@pokemon)
        else
          pokemon2 = -1
          pbMessage(_INTL("Please select a Pokémon to swap from your party."))
          pbChoosePokemon(1,2)
          poke = pbGet(1)
          if poke != -1
            pokemon2 = $Trainer.party[poke]
            pbRemovePokemonAt(poke)
            pbAddToPartySilent(@pokemon)
          end
          next if pokemon2 == -1 || poke == -1
          oldcurbox = $PokemonStorage.currentBox
          storedbox = $PokemonStorage.pbStoreCaught(pokemon2)
          curboxname = $PokemonStorage[oldcurbox].name
          boxname = $PokemonStorage[storedbox].name
          creator = nil
          creator = pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
          if storedbox!=oldcurbox
            if creator
              pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
            else
              pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
            end
            pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon2.name,boxname))
          else
            if creator
              pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon2.name,creator))
            else
              pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon2.name))
            end
            pbMessage(_INTL("It was stored in box \"{1}.\"",boxname))
          end
          pbMessage(_INTL("\\me[Pkmn get]{2} was added to {1}'s party!",$Trainer.name,@pokemon.name))
        end
        break
      when 1
        if pbBoxesFull?
          pbMessage(_INTL("There's no more room for Pokémon in the storage!\1"))
          next
        end
        oldcurbox = $PokemonStorage.currentBox
        storedbox = $PokemonStorage.pbStoreCaught(@pokemon)
        curboxname = $PokemonStorage[oldcurbox].name
        boxname = $PokemonStorage[storedbox].name
        creator = nil
        creator = pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
        if storedbox!=oldcurbox
          if creator
            pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
          else
            pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
          end
          pbMessage(_INTL("{1} was transferred to box \"{2}.\"",@pokemon.name,boxname))
        else
          if creator
            pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",@pokemon.name,creator))
          else
            pbMessage(_INTL("{1} was transferred to someone's PC.\1",@pokemon.name))
          end
          pbMessage(_INTL("It was stored in box \"{1}.\"",boxname))
        end
        break
      when 2
        pbFadeOutIn(99999){
          scene = PokemonSummary_Scene.new
          screen = PokemonSummaryScreen.new(scene,true)
          screen.pbStartScreen([@pokemon],0)
        }
      when 3
        pbFadeOutIn(99999){
          scene = PokemonSummary_Scene.new
          screen = PokemonSummaryScreen.new(scene,true)
          screen.pbStartScreen($Trainer.party,0)
        }
      end
    end
    return cmd
  end
end

def pbNicknameAndStore(pokemon)
  pbStorePokemon(pokemon)
end

def pbStorePokemon(pokemon)
  pbFadeOutIn(99999){
    CapturePokemonUI.new(pokemon)
  }
end

module PokeBattle_BattleCommon
  def pbStorePokemon(pkmn)
    ret = -1
    pbFadeOutIn(99999){
      ret = CapturePokemonUI.new(pkmn)
    }
    @initialItems[0][pbPlayer.party.length-1] = pkmn.item if @initialItems && ret == 0
  end
end

class PokemonEggHatch_Scene
  def pbMain
    pbBGMPlay("Evolution")
    # Egg animation
    updateScene(Graphics.frame_rate*15/10)
    pbPositionHatchMask(0)
    pbSEPlay("Battle ball shake")
    swingEgg(4)
    updateScene(Graphics.frame_rate*2/10)
    pbPositionHatchMask(1)
    pbSEPlay("Battle ball shake")
    swingEgg(4)
    updateScene(Graphics.frame_rate*4/10)
    pbPositionHatchMask(2)
    pbSEPlay("Battle ball shake")
    swingEgg(8,2)
    updateScene(Graphics.frame_rate*4/10)
    pbPositionHatchMask(3)
    pbSEPlay("Battle ball shake")
    swingEgg(16,4)
    updateScene(Graphics.frame_rate*2/10)
    pbPositionHatchMask(4)
    pbSEPlay("Battle recall")
    # Fade and change the sprite
    fadeTime = Graphics.frame_rate*4/10
    toneDiff = (255.0/fadeTime).ceil
    for i in 1..fadeTime
      @sprites["pokemon"].tone=Tone.new(i*toneDiff,i*toneDiff,i*toneDiff)
      @sprites["overlay"].opacity=i*toneDiff
      updateScene
    end
    updateScene(Graphics.frame_rate*3/4)
    @sprites["pokemon"].setPokemonBitmap(@pokemon) # Pokémon sprite
    @sprites["pokemon"].x = Graphics.width/2
    @sprites["pokemon"].y = 264
    pbApplyBattlerMetricsToSprite(@sprites["pokemon"],1,@pokemon.fSpecies)
    @sprites["hatch"].visible=false
    for i in 1..fadeTime
      @sprites["pokemon"].tone=Tone.new(255-i*toneDiff,255-i*toneDiff,255-i*toneDiff)
      @sprites["overlay"].opacity=255-i*toneDiff
      updateScene
    end
    @sprites["pokemon"].tone=Tone.new(0,0,0)
    @sprites["overlay"].opacity=0
    # Finish scene
    frames=pbCryFrameLength(@pokemon)
    pbPlayCry(@pokemon)
    updateScene(frames)
    pbBGMStop()
    pbMEPlay("Evolution success")
    pbMessage(_INTL("\\se[]{1} hatched from the Egg!\\wt[80]",@pokemon.name)) { update }
    if $Trainer.pokedex && !($Trainer.seen?(@pokemon.species) || $Trainer.owned?(@pokemon.species))# && !battle
      $Trainer.seen[@pokemon.species]  = true
      $Trainer.owned[@pokemon.species] = true
      pbSeenForm(@pokemon)
      pbMessage(_INTL("{1}'s data was added to the Pokédex.",@pokemon.name))
      dexscene = PokemonPokedexInfo_Scene.new
      dexscreen = PokemonPokedexInfoScreen.new(dexscene)
      dexscreen.pbDexEntry(@pokemon.species)
    end
    if pbConfirmMessage(
        _INTL("Would you like to nickname the newly hatched {1}?",@pokemon.name)) { update }
      nickname=pbEnterPokemonName(_INTL("{1}'s nickname?",@pokemon.name),
         0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,"",@pokemon,true)
      @pokemon.name=nickname if nickname!=""
      @nicknamed=true
    end
  end
end

def pbHatch(pokemon)
  speciesname = pokemon.speciesName
  pokemon.name           = speciesname
  pokemon.trainerID      = $Trainer.id
  pokemon.ot             = $Trainer.name
  pokemon.happiness      = 120
  pokemon.timeEggHatched = pbGetTimeNow
  pokemon.obtainMode     = 1   # hatched from egg
  pokemon.hatchedMap     = $game_map.map_id
  pokemon.pbRecordFirstMoves
  if !pbHatchAnimation(pokemon)
    pbMessage(_INTL("Huh?\1"))
    pbMessage(_INTL("...\1"))
    pbMessage(_INTL("... .... .....\1"))
    pbMessage(_INTL("{1} hatched from the Egg!",speciesname))
    if $Trainer.pokedex && !($Trainer.seen?(pokemon.species) || $Trainer.owned?(pokemon.species))# && !battle
      $Trainer.seen[pokemon.species]  = true
      $Trainer.owned[pokemon.species] = true
      pbSeenForm(pokemon)
      pbMessage(_INTL("{1}'s data was added to the Pokédex.",pokemon.name))
      dexscene = PokemonPokedexInfo_Scene.new
      dexscreen = PokemonPokedexInfoScreen.new(dexscene)
      dexscreen.pbDexEntry(pokemon.species)
    end
    if pbConfirmMessage(_INTL("Would you like to nickname the newly hatched {1}?",speciesname))
      nickname = pbEnterPokemonName(_INTL("{1}'s nickname?",speciesname),
         0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,"",pokemon)
      pokemon.name = nickname if nickname!=""
    end
  end
end

class PokemonEvolutionScene
  def pbEvolutionSuccess
    # Play cry of evolved species
    frames = pbCryFrameLength(@newspecies,@pokemon.form)
    pbBGMStop
    pbPlayCrySpecies(@newspecies,@pokemon.form)
    frames.times do
      Graphics.update
      pbUpdate
    end
    # Success jingle/message
    pbMEPlay("Evolution success")
    newspeciesname = PBSpecies.getName(@newspecies)
    oldspeciesname = PBSpecies.getName(@pokemon.species)
    pbMessageDisplay(@sprites["msgwindow"],
       _INTL("\\se[]Congratulations! Your {1} evolved into {2}!\\wt[80]",
       @pokemon.name,newspeciesname)) { pbUpdate }
    @sprites["msgwindow"].text = ""
    # Check for consumed item and check if Pokémon should be duplicated
    pbEvolutionMethodAfterEvolution
    # Modify Pokémon to make it evolved
    @pokemon.species = @newspecies
    @pokemon.name    = newspeciesname if @pokemon.name==oldspeciesname
    @pokemon.form    = 0 if @pokemon.isSpecies?(:MOTHIM)
    @pokemon.calcStats
    # See and own evolved species
    if $Trainer.pokedex && !($Trainer.seen?(@pokemon.species) || $Trainer.owned?(@pokemon.species))# && !battle
      $Trainer.seen[@pokemon.species]  = true
      $Trainer.owned[@pokemon.species] = true
      pbSeenForm(@pokemon)
      pbMessage(_INTL("{1}'s data was added to the Pokédex.",@pokemon.name))
      dexscene = PokemonPokedexInfo_Scene.new
      dexscreen = PokemonPokedexInfoScreen.new(dexscene)
      dexscreen.pbDexEntry(@pokemon.species)
    end
    # Learn moves upon evolution for evolved species
    movelist = @pokemon.getMoveList
    for i in movelist
      next if i[0]!=0 && i[0]!=@pokemon.level   # 0 is "learn upon evolution"
      pbLearnMove(@pokemon,i[1],true) { pbUpdate }
    end
  end
end

class PokemonTrade_Scene
  def pbTrade
    pbBGMStop
    pbPlayCry(@pokemon)
    speciesname1=PBSpecies.getName(@pokemon.species)
    speciesname2=PBSpecies.getName(@pokemon2.species)
    pbMessageDisplay(@sprites["msgwindow"],
       _ISPRINTF("{1:s}\r\nID: {2:05d}   OT: {3:s}\\wtnp[0]",
       @pokemon.name,@pokemon.publicID,@pokemon.ot)) { pbUpdate }
    pbMessageWaitForInput(@sprites["msgwindow"],50,true) { pbUpdate }
    pbPlayDecisionSE
    pbScene1
    pbMessageDisplay(@sprites["msgwindow"],
       _INTL("For {1}'s {2},\r\n{3} sends {4}.\1",@trader1,speciesname1,@trader2,speciesname2)) { pbUpdate }
    pbMessageDisplay(@sprites["msgwindow"],
       _INTL("{1} bids farewell to {2}.",@trader2,speciesname2)) { pbUpdate }
    pbScene2
    pbMessageDisplay(@sprites["msgwindow"],
       _ISPRINTF("{1:s}\r\nID: {2:05d}   OT: {3:s}\1",
       @pokemon2.name,@pokemon2.publicID,@pokemon2.ot)) { pbUpdate }
    pbMessageDisplay(@sprites["msgwindow"],
       _INTL("Take good care of {1}.",speciesname2)) { pbUpdate }
    if $Trainer.pokedex && !($Trainer.seen?(@pokemon2.species) || $Trainer.owned?(@pokemon2.species))# && !battle
      $Trainer.seen[@pokemon2.species]  = true
      $Trainer.owned[@pokemon2.species] = true
      pbSeenForm(@pokemon2)
      pbMessage(_INTL("{1}'s data was added to the Pokédex.",@pokemon2.name))
      dexscene = PokemonPokedexInfo_Scene.new
      dexscreen = PokemonPokedexInfoScreen.new(dexscene)
      dexscreen.pbDexEntry(@pokemon2.species)
    end
  end
end
